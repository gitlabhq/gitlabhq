import state from './state';
import * as actions from './actions';
import mutations from './mutations';
import * as getters from './getters';

export default {
  namespaced: true,
  state: state(),
  actions,
  mutations,
  getters,
};
