import createState from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';

export default {
  namespaced: true,
  actions,
  state: createState(),
  getters,
  mutations,
};
