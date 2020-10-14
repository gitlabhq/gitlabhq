import createState from 'ee_else_ce/vuex_shared/modules/members/state';
import * as actions from './actions';
import mutations from './mutations';

export default initialState => ({
  namespaced: true,
  state: createState(initialState),
  actions,
  mutations,
});
