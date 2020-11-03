import state from './state';
import mutations from './mutations';
import * as actions from './actions';
import * as getters from './getters';

export default data => ({
  state: state(data),
  actions,
  getters,
  mutations,
  namespaced: true,
});
