import * as types from './mutation_types';

export const setInitialState = ({ commit }, props) => commit(types.SET_INITIAL_STATE, props);

export const toggleDropdownButton = ({ commit }) => commit(types.TOGGLE_DROPDOWN_BUTTON);
export const toggleDropdownContents = ({ commit }) => commit(types.TOGGLE_DROPDOWN_CONTENTS);

export const toggleDropdownContentsCreateView = ({ commit }) =>
  commit(types.TOGGLE_DROPDOWN_CONTENTS_CREATE_VIEW);

export const updateSelectedLabels = ({ commit }, labels) =>
  commit(types.UPDATE_SELECTED_LABELS, { labels });
