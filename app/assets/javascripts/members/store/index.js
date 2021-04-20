import * as actions from 'ee_else_ce/members/store/actions';
import mutations from 'ee_else_ce/members/store/mutations';
import createState from 'ee_else_ce/members/store/state';

export default (initialState) => ({
  namespaced: true,
  state: createState(initialState),
  actions,
  mutations,
});
