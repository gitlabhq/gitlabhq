import state from './state';
import * as actions from './actions';
import mutations from './mutations';

export default () => ({
  namespaced: true,
  actions,
  mutations,
  state: state(),
});
