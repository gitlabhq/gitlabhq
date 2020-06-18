import * as types from './mutation_types';

export const toggleOpen = ({ dispatch, state }) => {
  if (state.isOpen) {
    dispatch('close');
  } else {
    dispatch('open');
  }
};

export const open = ({ state, commit }, view) => {
  commit(types.SET_OPEN, true);

  if (view && view.name !== state.currentView) {
    const { name, keepAlive } = view;

    commit(types.SET_CURRENT_VIEW, name);

    if (keepAlive) {
      commit(types.KEEP_ALIVE_VIEW, name);
    }
  }
};

export const close = ({ commit }) => {
  commit(types.SET_OPEN, false);
};
