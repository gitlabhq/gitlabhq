import flash from '../../../flash';
import service from '../../services';
import * as types from '../mutation_types';
import { activeFile } from '../getters';

export const closeFile = ({ commit }, file) => {
  if (file.changed || file.tempFile) return;

  commit(types.TOGGLE_FILE_OPEN, file);
  commit(types.SET_FILE_ACTIVE, { file, active: false });
};

export const setFileActive = ({ commit, state }, file) => {
  const currentActiveFile = activeFile(state);

  if (currentActiveFile) {
    commit(types.SET_FILE_ACTIVE, { file: currentActiveFile, active: false });
  }

  commit(types.SET_FILE_ACTIVE, { file, active: true });
};

export const getFileData = ({ commit, dispatch }, file) => {
  commit(types.TOGGLE_LOADING, file);

  service.getFileData(file.url)
    .then(res => res.json())
    .then((data) => {
      commit(types.SET_FILE_DATA, { data, file });
      commit(types.SET_PREVIEW_MODE);
      commit(types.TOGGLE_FILE_OPEN, file);
      dispatch('setFileActive', file);
      commit(types.TOGGLE_LOADING, file);
    })
    .catch(() => {
      commit(types.TOGGLE_LOADING, file);
      flash('Error loading file data. Please try again.');
    });
};

export const getRawFileData = ({ commit, dispatch }, file) => service.getRawFileData(file.rawPath)
  .then(res => res.text())
  .then((raw) => {
    commit(types.SET_FILE_RAW_DATA, { file, raw });
  })
  .catch(() => flash('Error loading file content. Please try again.'));

export const changeFileContent = ({ commit }, { file, content }) => {
  commit(types.UPDATE_FILE_CONTENT, { file, content });
};
