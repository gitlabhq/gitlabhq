import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

export default () => ({
  namespaced: true,
  actions,
  state: createState(),
  getters,
  mutations,
});
