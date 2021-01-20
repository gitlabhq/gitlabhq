export const metricsWithData = (state, getters, rootState, rootGetters) =>
  state.modules.map((module) => rootGetters[`${module}/metricsWithData`]().length);
