import createState from './state';
import * as actions from './actions';
import mutations from './mutations';

export default initialState => ({
  namespaced: true,
  actions,
  mutations,
  state: createState(initialState),
});
