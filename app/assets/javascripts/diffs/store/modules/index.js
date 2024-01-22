import * as getters from 'ee_else_ce/diffs/store/getters';
import createState from 'ee_else_ce/diffs/store/modules/diff_state';
import mutations from 'ee_else_ce/diffs/store/mutations';
import * as actions from '../actions';

export default () => ({
  namespaced: true,
  state: createState(),
  getters,
  actions,
  mutations,
});
