import Vuex from 'vuex';

export default ({ modules, featureFlags }) =>
  new Vuex.Store({
    modules,
    state: { featureFlags },
  });
