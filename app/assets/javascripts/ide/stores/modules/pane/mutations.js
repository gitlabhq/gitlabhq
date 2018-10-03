import * as types from './mutation_types';

export default {
  [types.SET_OPEN](state, isOpen) {
    Object.assign(state, {
      isOpen,
    });
  },
  [types.SET_CURRENT_VIEW](state, currentView) {
    Object.assign(state, {
      currentView,
    });
  },
  [types.KEEP_ALIVE_VIEW](state, viewName) {
    Object.assign(state.keepAliveViews, {
      [viewName]: true,
    });
  },
};
