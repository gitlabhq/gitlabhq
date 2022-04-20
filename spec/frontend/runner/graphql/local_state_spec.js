import createApolloClient from '~/lib/graphql';
import { createLocalState } from '~/runner/graphql/list/local_state';
import getCheckedRunnerIdsQuery from '~/runner/graphql/list/checked_runner_ids.query.graphql';

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

  describe('default', () => {
    it('has empty checked list', () => {
      expect(queryCheckedRunnerIds()).toEqual([]);
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
        localState.localMutations.setRunnerChecked({ runner: { id }, isChecked: true });
      });

      expect(queryCheckedRunnerIds()).toEqual(['a', 'b', 'c']);

      localState.localMutations.clearChecked();

      expect(queryCheckedRunnerIds()).toEqual([]);
    });
  });
});
