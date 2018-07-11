import * as actions from '../actions';
import * as getters from '../getters';
import mutations from '../mutations';
import createState from './diff_state';

export default {
  namespaced: true,
  state: createState(),
  getters,
  actions,
  mutations,
};
