import Cookies from 'js-cookie';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { INTERACTIVE_RESOLVE_MODE, EDIT_RESOLVE_MODE } from '../constants';
import { decorateFiles, restoreFileLinesState, markLine } from '../utils';
import * as types from './mutation_types';

export const fetchConflictsData = async ({ commit, dispatch }, conflictsPath) => {
  commit(types.SET_LOADING_STATE, true);
  try {
    const { data } = await axios.get(conflictsPath);
    if (data.type === 'error') {
      commit(types.SET_FAILED_REQUEST, data.message);
    } else {
      dispatch('setConflictsData', data);
    }
  } catch (e) {
    commit(types.SET_FAILED_REQUEST);
  }
  commit(types.SET_LOADING_STATE, false);
};

export const setConflictsData = async ({ commit }, data) => {
  const files = decorateFiles(data.files);
  commit(types.SET_CONFLICTS_DATA, { ...data, files });
};

export const submitResolvedConflicts = async ({ commit, getters }, resolveConflictsPath) => {
  commit(types.SET_SUBMIT_STATE, true);
  try {
    const { data } = await axios.post(resolveConflictsPath, getters.getCommitData);
    window.location.assign(data.redirect_to);
  } catch (e) {
    commit(types.SET_SUBMIT_STATE, false);
    createFlash({ message: __('Failed to save merge conflicts resolutions. Please try again!') });
  }
};

export const setLoadingState = ({ commit }, isLoading) => {
  commit(types.SET_LOADING_STATE, isLoading);
};

export const setErrorState = ({ commit }, hasError) => {
  commit(types.SET_ERROR_STATE, hasError);
};

export const setFailedRequest = ({ commit }, message) => {
  commit(types.SET_FAILED_REQUEST, message);
};

export const setViewType = ({ commit }, viewType) => {
  commit(types.SET_VIEW_TYPE, viewType);
  Cookies.set('diff_view', viewType);
};

export const setSubmitState = ({ commit }, isSubmitting) => {
  commit(types.SET_SUBMIT_STATE, isSubmitting);
};

export const updateCommitMessage = ({ commit }, commitMessage) => {
  commit(types.UPDATE_CONFLICTS_DATA, { commitMessage });
};

export const setFileResolveMode = ({ commit, state, getters }, { file, mode }) => {
  const index = getters.getFileIndex(file);
  const updated = { ...state.conflictsData.files[index] };
  if (mode === INTERACTIVE_RESOLVE_MODE) {
    updated.showEditor = false;
  } else if (mode === EDIT_RESOLVE_MODE) {
    // Restore Interactive mode when switching to Edit mode
    updated.showEditor = true;
    updated.loadEditor = true;
    updated.resolutionData = {};

    const { inlineLines, parallelLines } = restoreFileLinesState(updated);
    updated.parallelLines = parallelLines;
    updated.inlineLines = inlineLines;
  }
  updated.resolveMode = mode;
  commit(types.UPDATE_FILE, { file: updated, index });
};

export const setPromptConfirmationState = (
  { commit, state, getters },
  { file, promptDiscardConfirmation },
) => {
  const index = getters.getFileIndex(file);
  const updated = { ...state.conflictsData.files[index], promptDiscardConfirmation };
  commit(types.UPDATE_FILE, { file: updated, index });
};

export const handleSelected = ({ commit, state, getters }, { file, line: { id, section } }) => {
  const index = getters.getFileIndex(file);
  const updated = { ...state.conflictsData.files[index] };
  updated.resolutionData = { ...updated.resolutionData, [id]: section };

  updated.inlineLines = file.inlineLines.map((line) => {
    if (id === line.id && (line.hasConflict || line.isHeader)) {
      return markLine(line, section);
    }
    return line;
  });

  updated.parallelLines = file.parallelLines.map((lines) => {
    let left = { ...lines[0] };
    let right = { ...lines[1] };
    const hasSameId = right.id === id || left.id === id;
    const isLeftMatch = left.hasConflict || left.isHeader;
    const isRightMatch = right.hasConflict || right.isHeader;

    if (hasSameId && (isLeftMatch || isRightMatch)) {
      left = markLine(left, section);
      right = markLine(right, section);
    }
    return [left, right];
  });

  commit(types.UPDATE_FILE, { file: updated, index });
};

export const updateFile = ({ commit, getters }, file) => {
  const index = getters.getFileIndex(file);
  commit(types.UPDATE_FILE, { file, index });
};
