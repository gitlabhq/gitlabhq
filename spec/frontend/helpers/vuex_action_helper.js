const noop = () => {};

/**
 * Helper for testing action with expected mutations inspired in
 * https://vuex.vuejs.org/en/testing.html
 *
 * @param {(Function|Object)} action to be tested, or object of named parameters
 * @param {Object} payload will be provided to the action
 * @param {Object} state will be provided to the action
 * @param {Array} [expectedMutations=[]] mutations expected to be committed
 * @param {Array} [expectedActions=[]] actions expected to be dispatched
 * @param {Function} [done=noop] to be executed after the tests
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
 *   done,
 * );
 *
 * @example
 * testAction(
 *   actions.actionName, // action
 *   { }, // mocked payload
 *   state, //state
 *   [ { type: types.MUTATION} ], // expected mutations
 *   [], // expected actions
 * ).then(done)
 * .catch(done.fail);
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
  doneArg = noop,
) => {
  let action = actionArg;
  let payload = payloadArg;
  let state = stateArg;
  let expectedMutations = expectedMutationsArg;
  let expectedActions = expectedActionsArg;
  let done = doneArg;

  if (typeof actionArg !== 'function') {
    ({
      action,
      payload,
      state,
      expectedMutations = [],
      expectedActions = [],
      done = noop,
    } = actionArg);
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
  };

  const validateResults = () => {
    expect({
      mutations,
      actions,
    }).toEqual({
      mutations: expectedMutations,
      actions: expectedActions,
    });
    done();
  };

  const result = action(
    { commit, state, dispatch, rootState: state, rootGetters: state, getters: state },
    payload,
  );

  return (result || new Promise((resolve) => setImmediate(resolve)))
    .catch((error) => {
      validateResults();
      throw error;
    })
    .then((data) => {
      validateResults();
      return data;
    });
};
