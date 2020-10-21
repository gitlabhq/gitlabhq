import Vuex from 'vuex';
import * as getters from './getters';

export default ({ modules, featureFlags }) =>
  new Vuex.Store({
    modules,
    state: { featureFlags },
    getters,
  });
