import * as getters from '../getters';
import mutations from '../mutations';
import * as actions from '../actions';
import createState from './diff_state';

export default () => ({
  namespaced: true,
  state: createState(),
  getters,
  actions,
  mutations,
});
