import { normalizeHeaders } from '~/lib/utils/common_utils';
import flash from '~/flash';
import service from '../../services';
import * as types from '../mutation_types';
import router from '../../ide_router';
import {
  findEntry,
  setPageTitle,
  createTemp,
} from '../utils';

export const closeFile = ({ commit, state, getters, dispatch }, path) => {
  const indexOfClosedFile = state.openFiles.indexOf(path);
  const file = state.entries[path];
  const fileWasActive = file.active;

  commit(types.TOGGLE_FILE_OPEN, path);
  commit(types.SET_FILE_ACTIVE, { path, active: false });

  if (state.openFiles.length > 0 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 0 : indexOfClosedFile - 1;
    const nextFileToOpen = state.entries[state.openFiles[nextIndexToOpen]];

    router.push(`/project${nextFileToOpen.url}`);
  } else if (!state.openFiles.length) {
    router.push(`/project/${file.projectId}/tree/${file.branchId}/`);
  }

  dispatch('getLastCommitData');
};

export const setFileActive = ({ commit, state, getters, dispatch }, path) => {
  const file = state.entries[path];
  const currentActiveFile = getters.activeFile;

  if (file.active) return;

  if (currentActiveFile) {
    commit(types.SET_FILE_ACTIVE, { path: currentActiveFile.path, active: false });
  }

  commit(types.SET_FILE_ACTIVE, { path, active: true });
  dispatch('scrollToTab');

  // reset hash for line highlighting
  location.hash = '';

  commit(types.SET_CURRENT_PROJECT, file.projectId);
  commit(types.SET_CURRENT_BRANCH, file.branchId);
};

export const getFileData = ({ state, commit, dispatch }, file) => {
  commit(types.TOGGLE_LOADING, { entry: file });

  service.getFileData(file.url)
    .then((res) => {
      const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);

      setPageTitle(pageTitle);

      return res.json();
    })
    .then((data) => {
      commit(types.SET_FILE_DATA, { data, file });
      commit(types.TOGGLE_FILE_OPEN, file.path);
      dispatch('setFileActive', file.path);
      commit(types.TOGGLE_LOADING, { entry: file });
    })
    .catch(() => {
      commit(types.TOGGLE_LOADING, { entry: file });
      flash('Error loading file data. Please try again.', 'alert', document, null, false, true);
    });
};

export const getRawFileData = ({ commit, dispatch }, file) => service.getRawFileData(file)
  .then((raw) => {
    commit(types.SET_FILE_RAW_DATA, { file, raw });
  })
  .catch(() => flash('Error loading file content. Please try again.', 'alert', document, null, false, true));

export const changeFileContent = ({ state, commit }, { path, content }) => {
  const file = state.entries[path];
  commit(types.UPDATE_FILE_CONTENT, { path, content });

  const indexOfChangedFile = state.changedFiles.indexOf(path);

  if (!file.changed && indexOfChangedFile === -1) {
    commit(types.ADD_FILE_TO_CHANGED, path);
  } else if (file.changed && indexOfChangedFile !== -1) {
    commit(types.REMOVE_FILE_FROM_CHANGED, path);
  }
};

export const setFileLanguage = ({ getters, commit }, { fileLanguage }) => {
  if (getters.activeFile) {
    commit(types.SET_FILE_LANGUAGE, { file: getters.activeFile, fileLanguage });
  }
};

export const setFileEOL = ({ getters, commit }, { eol }) => {
  if (getters.activeFile) {
    commit(types.SET_FILE_EOL, { file: getters.activeFile, eol });
  }
};

export const setEditorPosition = ({ getters, commit }, { editorRow, editorColumn }) => {
  if (getters.activeFile) {
    commit(types.SET_FILE_POSITION, { file: getters.activeFile, editorRow, editorColumn });
  }
};

export const createTempFile = ({ state, commit, dispatch }, { projectId, branchId, parent, name, content = '', base64 = '' }) => {
  const path = parent.path !== undefined ? parent.path : '';
  // We need to do the replacement otherwise the web_url + file.url duplicate
  const newUrl = `/${projectId}/blob/${branchId}/${path}${path ? '/' : ''}${name}`;
  const file = createTemp({
    projectId,
    branchId,
    name: name.replace(`${path}/`, ''),
    path,
    type: 'blob',
    level: parent.level !== undefined ? parent.level + 1 : 0,
    changed: true,
    content,
    base64,
    url: newUrl,
  });

  if (findEntry(parent.tree, 'blob', file.name)) return flash(`The name "${file.name}" is already taken in this directory.`, 'alert', document, null, false, true);

  commit(types.CREATE_TMP_FILE, {
    parent,
    file,
  });
  commit(types.TOGGLE_FILE_OPEN, file.path);
  commit(types.ADD_FILE_TO_CHANGED, file.path);
  dispatch('setFileActive', file.path);

  router.push(`/project${file.url}`);

  return Promise.resolve(file);
};

export const discardFileChanges = ({ commit }, file) => {
  commit(types.DISCARD_FILE_CHANGES, file);
  commit(types.REMOVE_FILE_FROM_CHANGED, file);

  if (file.tempFile && file.opened) {
    commit(types.TOGGLE_FILE_OPEN, file.path);
  }
};
