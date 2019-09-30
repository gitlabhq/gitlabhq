import * as getters from './getters';
import actions from './actions';
import mutations from './mutations';
import state from './state';

const createStore = fetchFn => ({
  actions: actions(fetchFn),
  getters,
  mutations,
  state: state(),
});

export default createStore;
