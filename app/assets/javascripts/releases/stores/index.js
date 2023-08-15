// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

export default ({ modules, featureFlags }) =>
  new Vuex.Store({
    modules,
    state: { featureFlags },
  });
