import createState from 'ee_else_ce/vuex_shared/modules/members/state';
import mutations from 'ee_else_ce/vuex_shared/modules/members/mutations';
import * as actions from 'ee_else_ce/vuex_shared/modules/members/actions';

export default initialState => ({
  namespaced: true,
  state: createState(initialState),
  actions,
  mutations,
});
