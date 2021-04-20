import * as actions from 'ee_else_ce/diffs/store/actions';
import createState from 'ee_else_ce/diffs/store/modules/diff_state';
import mutations from 'ee_else_ce/diffs/store/mutations';
import * as getters from '../getters';

export default () => ({
  namespaced: true,
  state: createState(),
  getters,
  actions,
  mutations,
});
