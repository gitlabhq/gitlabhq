import createState from 'ee_else_ce/members/store/state';
import mutations from 'ee_else_ce/members/store/mutations';
import * as actions from 'ee_else_ce/members/store/actions';

export default initialState => ({
  state: createState(initialState),
  actions,
  mutations,
});
