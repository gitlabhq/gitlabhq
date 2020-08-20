// eslint-disable-next-line import/prefer-default-export
export const metricsWithData = (state, getters, rootState, rootGetters) =>
  state.modules.map(module => rootGetters[`${module}/metricsWithData`]().length);
