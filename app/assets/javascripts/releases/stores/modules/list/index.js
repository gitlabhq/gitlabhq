import * as actions from './actions';
import mutations from './mutations';
import createState from './state';

export default (initialState) => ({
  namespaced: true,
  actions,
  mutations,
  state: createState(initialState),
});
