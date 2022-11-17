import { gql } from '@apollo/client/core';
import createApolloClient from '~/lib/graphql';
import { createLocalState } from '~/ci/runner/graphql/list/local_state';
import getCheckedRunnerIdsQuery from '~/ci/runner/graphql/list/checked_runner_ids.query.graphql';
import { RUNNER_TYPENAME } from '~/ci/runner/constants';

const makeRunner = (id, deleteRunner = true) => ({
  id,
  userPermissions: {
    deleteRunner,
  },
});

describe('~/ci/runner/graphql/list/local_state', () => {
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
      const id = 'a';

      addMockRunnerToCache(id);
      localState.localMutations.setRunnerChecked({
        runner: makeRunner(id),
        isChecked: true,
      });

      expect(queryCheckedRunnerIds()).toEqual(['a']);
    });

    it('return checked runners that are not dangling references', () => {
      addMockRunnerToCache('a'); // 'b' is missing from the cache, perhaps because it was deleted
      localState.localMutations.setRunnerChecked({ runner: makeRunner('a'), isChecked: true });
      localState.localMutations.setRunnerChecked({ runner: makeRunner('b'), isChecked: true });

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
        localState.localMutations.setRunnerChecked({ runner: makeRunner(id), isChecked });
      });
    });
    it(`for inputs="${inputs}" has a ids="[${expected}]"`, () => {
      expect(queryCheckedRunnerIds()).toEqual(expected);
    });
  });

  describe.each`
    inputs                                       | expected
    ${[[['a', 'b'], true]]}                      | ${['a', 'b']}
    ${[[['a', 'b'], false]]}                     | ${[]}
    ${[[['a', 'b'], true], [['c', 'd'], true]]}  | ${['a', 'b', 'c', 'd']}
    ${[[['a', 'b'], true], [['a', 'b'], false]]} | ${[]}
    ${[[['a', 'b'], true], [['b'], false]]}      | ${['a']}
  `('setRunnersChecked', ({ inputs, expected }) => {
    beforeEach(() => {
      inputs.forEach(([ids, isChecked]) => {
        ids.forEach(addMockRunnerToCache);

        localState.localMutations.setRunnersChecked({
          runners: ids.map((id) => makeRunner(id)),
          isChecked,
        });
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
        localState.localMutations.setRunnerChecked({ runner: makeRunner(id), isChecked: true });
      });

      expect(queryCheckedRunnerIds()).toEqual(['a', 'b', 'c']);

      localState.localMutations.clearChecked();

      expect(queryCheckedRunnerIds()).toEqual([]);
    });
  });

  describe('when some runners cannot be deleted', () => {
    beforeEach(() => {
      addMockRunnerToCache('a');
      addMockRunnerToCache('b');
    });

    it('setRunnerChecked does not check runner that cannot be deleted', () => {
      localState.localMutations.setRunnerChecked({
        runner: makeRunner('a', false),
        isChecked: true,
      });

      expect(queryCheckedRunnerIds()).toEqual([]);
    });

    it('setRunnersChecked does not check runner that cannot be deleted', () => {
      localState.localMutations.setRunnersChecked({
        runners: [makeRunner('a', false), makeRunner('b', false)],
        isChecked: true,
      });

      expect(queryCheckedRunnerIds()).toEqual([]);
    });
  });
});
