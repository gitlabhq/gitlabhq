import { normalizeHeaders } from '../../../lib/utils/common_utils';
import flash from '../../../flash';
import service from '../../services';
import * as types from '../mutation_types';
import {
  findEntry,
  pushState,
  setPageTitle,
  createTemp,
  findIndexOfFile,
} from '../utils';

export const closeFile = ({ commit, state, dispatch }, { file, force = false }) => {
  if ((file.changed || file.tempFile) && !force) return;

  const indexOfClosedFile = findIndexOfFile(state.openFiles, file);
  const fileWasActive = file.active;

  commit(types.TOGGLE_FILE_OPEN, file);
  commit(types.SET_FILE_ACTIVE, { file, active: false });

  if (state.openFiles.length > 0 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 0 : indexOfClosedFile - 1;
    const nextFileToOpen = state.openFiles[nextIndexToOpen];

    dispatch('setFileActive', nextFileToOpen);
  } else if (!state.openFiles.length) {
    pushState(file.parentTreeUrl);
  }

  dispatch('getLastCommitData');
};

export const setFileActive = ({ commit, state, getters, dispatch }, file) => {
  const currentActiveFile = getters.activeFile;

  if (file.active) return;

  if (currentActiveFile) {
    commit(types.SET_FILE_ACTIVE, { file: currentActiveFile, active: false });
  }

  commit(types.SET_FILE_ACTIVE, { file, active: true });
  dispatch('scrollToTab');

  // reset hash for line highlighting
  location.hash = '';
};

export const getFileData = ({ state, commit, dispatch }, file) => {
  commit(types.TOGGLE_LOADING, file);

  service.getFileData(file.url)
    .then((res) => {
      const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);

      setPageTitle(pageTitle);

      return res.json();
    })
    .then((data) => {
      commit(types.SET_FILE_DATA, { data, file });
      commit(types.TOGGLE_FILE_OPEN, file);
      dispatch('setFileActive', file);
      commit(types.TOGGLE_LOADING, file);

      pushState(file.url);
    })
    .catch(() => {
      commit(types.TOGGLE_LOADING, file);
      flash('Error loading file data. Please try again.');
    });
};

export const getRawFileData = ({ commit, dispatch }, file) => service.getRawFileData(file)
  .then((raw) => {
    commit(types.SET_FILE_RAW_DATA, { file, raw });
  })
  .catch(() => flash('Error loading file content. Please try again.'));

export const changeFileContent = ({ commit }, { file, content }) => {
  commit(types.UPDATE_FILE_CONTENT, { file, content });
};

export const createTempFile = ({ state, commit, dispatch }, { tree, name, content = '', base64 = '' }) => {
  const file = createTemp({
    name: name.replace(`${state.path}/`, ''),
    path: tree.path,
    type: 'blob',
    level: tree.level !== undefined ? tree.level + 1 : 0,
    changed: true,
    content,
    base64,
  });

  if (findEntry(tree, 'blob', file.name)) return flash(`The name "${file.name}" is already taken in this directory.`);

  commit(types.CREATE_TMP_FILE, {
    parent: tree,
    file,
  });
  commit(types.TOGGLE_FILE_OPEN, file);
  dispatch('setFileActive', file);

  if (!state.editMode && !file.base64) {
    dispatch('toggleEditMode', true);
  }

  return Promise.resolve(file);
};
