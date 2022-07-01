import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';

export default (initialState) => {
  return {
    namespaced: true,
    actions,
    getters,
    mutations,
    state: state(initialState),
  };
};
