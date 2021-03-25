import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';

export default (initialState) => ({
  namespaced: true,
  actions,
  getters,
  mutations,
  state: createState(initialState),
});
