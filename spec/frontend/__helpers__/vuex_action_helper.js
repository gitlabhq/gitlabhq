// eslint-disable-next-line no-restricted-syntax
import { setImmediate } from 'timers';

/** Helper for testing action with expected mutations inspired in
 * https://vuex.vuejs.org/en/testing.html
 *
 * @param {(Function|Object)} action to be tested, or object of named parameters
 * @param {Object} payload will be provided to the action
 * @param {Object} state will be provided to the action
 * @param {Array} [expectedMutations=[]] mutations expected to be committed
 * @param {Array} [expectedActions=[]] actions expected to be dispatched
 * @return {Promise}
 *
 * @example
 * testAction(
 *   actions.actionName, // action
 *   { }, // mocked payload
 *   state, //state
 *   // expected mutations
 *   [
 *    { type: types.MUTATION}
 *    { type: types.MUTATION_1, payload: expect.any(Number)}
 *   ],
 *   // expected actions
 *   [
 *    { type: 'actionName', payload: {param: 'foobar'}},
 *    { type: 'actionName1'}
 *   ]
 * );
 *
 * @example
 * await testAction({
 *   action: actions.actionName,
 *   payload: { deleteListId: 1 },
 *   state: { lists: [1, 2, 3] },
 *   expectedMutations: [ { type: types.MUTATION} ],
 *   expectedActions: [],
 * })
 */

export default (
  actionArg,
  payloadArg,
  stateArg,
  expectedMutationsArg = [],
  expectedActionsArg = [],
  // eslint-disable-next-line max-params
) => {
  let action = actionArg;
  let payload = payloadArg;
  let state = stateArg;
  let expectedMutations = expectedMutationsArg;
  let expectedActions = expectedActionsArg;

  if (typeof actionArg !== 'function') {
    ({ action, payload, state, expectedMutations = [], expectedActions = [] } = actionArg);
  }

  const mutations = [];
  const actions = [];

  // mock commit
  const commit = (type, mutationPayload) => {
    const mutation = { type };

    if (typeof mutationPayload !== 'undefined') {
      mutation.payload = mutationPayload;
    }

    mutations.push(mutation);
  };

  // mock dispatch
  const dispatch = (type, actionPayload) => {
    const dispatchedAction = { type };

    if (typeof actionPayload !== 'undefined') {
      dispatchedAction.payload = actionPayload;
    }

    actions.push(dispatchedAction);

    return Promise.resolve();
  };
  const validateResults = () => {
    expect({
      mutations,
      actions,
    }).toEqual({
      mutations: expectedMutations,
      actions: expectedActions,
    });
  };

  const result = action(
    { commit, state, dispatch, rootState: state, rootGetters: state, getters: state },
    payload,
  );

  return (
    result ||
    new Promise((resolve) => {
      // eslint-disable-next-line no-restricted-syntax
      setImmediate(resolve);
    })
  )
    .catch((error) => {
      validateResults();
      throw error;
    })
    .then((data) => {
      validateResults();
      return data;
    });
};
