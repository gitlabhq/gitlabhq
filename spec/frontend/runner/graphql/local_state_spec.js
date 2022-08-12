import { gql } from '@apollo/client/core';
import createApolloClient from '~/lib/graphql';
import { createLocalState } from '~/runner/graphql/list/local_state';
import getCheckedRunnerIdsQuery from '~/runner/graphql/list/checked_runner_ids.query.graphql';
import { RUNNER_TYPENAME } from '~/runner/constants';

describe('~/runner/graphql/list/local_state', () => {
  let localState;
  let apolloClient;

  const createSubject = () => {
    if (apolloClient) {
      throw new Error('test subject already exists!');
    }

    localState = createLocalState();

    const { cacheConfig, typeDefs } = localState;

    apolloClient = createApolloClient({}, { cacheConfig, typeDefs });
  };

  const addMockRunnerToCache = (id) => {
    // mock some runners in the cache to prevent dangling references
    apolloClient.writeFragment({
      id: `${RUNNER_TYPENAME}:${id}`,
      fragment: gql`
        fragment DummyRunner on CiRunner {
          __typename
        }
      `,
      data: {
        __typename: RUNNER_TYPENAME,
      },
    });
  };

  const queryCheckedRunnerIds = () => {
    const { checkedRunnerIds } = apolloClient.readQuery({
      query: getCheckedRunnerIdsQuery,
    });
    return checkedRunnerIds;
  };

  beforeEach(() => {
    createSubject();
  });

  afterEach(() => {
    localState = null;
    apolloClient = null;
  });

  describe('queryCheckedRunnerIds', () => {
    it('has empty checked list by default', () => {
      expect(queryCheckedRunnerIds()).toEqual([]);
    });

    it('returns checked runners that have a reference in the cache', () => {
      addMockRunnerToCache('a');
      localState.localMutations.setRunnerChecked({ runner: { id: 'a' }, isChecked: true });

      expect(queryCheckedRunnerIds()).toEqual(['a']);
    });

    it('return checked runners that are not dangling references', () => {
      addMockRunnerToCache('a'); // 'b' is missing from the cache, perhaps because it was deleted
      localState.localMutations.setRunnerChecked({ runner: { id: 'a' }, isChecked: true });
      localState.localMutations.setRunnerChecked({ runner: { id: 'b' }, isChecked: true });

      expect(queryCheckedRunnerIds()).toEqual(['a']);
    });
  });

  describe.each`
    inputs                                                   | expected
    ${[['a', true], ['b', true], ['b', true]]}               | ${['a', 'b']}
    ${[['a', true], ['b', true], ['a', false]]}              | ${['b']}
    ${[['c', true], ['b', true], ['a', true], ['d', false]]} | ${['c', 'b', 'a']}
  `('setRunnerChecked', ({ inputs, expected }) => {
    beforeEach(() => {
      inputs.forEach(([id, isChecked]) => {
        addMockRunnerToCache(id);
        localState.localMutations.setRunnerChecked({ runner: { id }, isChecked });
      });
    });
    it(`for inputs="${inputs}" has a ids="[${expected}]"`, () => {
      expect(queryCheckedRunnerIds()).toEqual(expected);
    });
  });

  describe('clearChecked', () => {
    it('clears all checked items', () => {
      ['a', 'b', 'c'].forEach((id) => {
        addMockRunnerToCache(id);
        localState.localMutations.setRunnerChecked({ runner: { id }, isChecked: true });
      });

      expect(queryCheckedRunnerIds()).toEqual(['a', 'b', 'c']);

      localState.localMutations.clearChecked();

      expect(queryCheckedRunnerIds()).toEqual([]);
    });
  });
});
