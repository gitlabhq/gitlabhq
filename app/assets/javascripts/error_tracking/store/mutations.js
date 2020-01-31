import * as types from './mutation_types';

export default {
  [types.SET_UPDATING_IGNORE_STATUS](state, updating) {
    state.updatingIgnoreStatus = updating;
  },
  [types.SET_UPDATING_RESOLVE_STATUS](state, updating) {
    state.updatingResolveStatus = updating;
  },
  [types.SET_ERROR_STATUS](state, status) {
    state.errorStatus = status;
  },
};
