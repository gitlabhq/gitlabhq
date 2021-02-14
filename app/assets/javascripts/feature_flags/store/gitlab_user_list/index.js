import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

export default (data) => ({
  state: state(data),
  actions,
  getters,
  mutations,
  namespaced: true,
});
