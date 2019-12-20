import * as getters from './getters';
import actions from './actions';
import mutations from './mutations';
import state from './state';

const createStore = ({ fetchFn, initialState }) => ({
  actions: actions(fetchFn),
  getters,
  mutations,
  state: Object.assign(state(), initialState || {}),
});

export default createStore;
