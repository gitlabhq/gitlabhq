import * as actions from './actions';
import mutations from './mutations';
import state from './state';

export default {
  namespaced: true,
  actions,
  mutations,
  state: state(),
};
