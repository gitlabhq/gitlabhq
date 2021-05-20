import * as actions from 'ee_else_ce/diffs/store/actions';
import * as getters from 'ee_else_ce/diffs/store/getters';
import createState from 'ee_else_ce/diffs/store/modules/diff_state';
import mutations from 'ee_else_ce/diffs/store/mutations';

export default () => ({
  namespaced: true,
  state: createState(),
  getters,
  actions,
  mutations,
});
