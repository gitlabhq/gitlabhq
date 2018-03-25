import { normalizeHeaders } from '~/lib/utils/common_utils';
import flash from '~/flash';
import eventHub from '../../eventhub';
import service from '../../services';
import * as types from '../mutation_types';
import router from '../../ide_router';
import { setPageTitle } from '../utils';

export const closeFile = ({ commit, state, getters, dispatch }, path) => {
  const indexOfClosedFile = state.openFiles.findIndex(f => f.path === path);
  const file = state.entries[path];
  const fileWasActive = file.active;

  commit(types.TOGGLE_FILE_OPEN, path);
  commit(types.SET_FILE_ACTIVE, { path, active: false });

  if (state.openFiles.length > 0 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 0 : indexOfClosedFile - 1;
    const nextFileToOpen = state.entries[state.openFiles[nextIndexToOpen].path];

    router.push(`/project${nextFileToOpen.url}`);
  } else if (!state.openFiles.length) {
    router.push(`/project/${file.projectId}/tree/${file.branchId}/`);
  }

  eventHub.$emit(`editor.update.model.dispose.${file.path}`);
};

export const setFileActive = ({ commit, state, getters, dispatch }, path) => {
  const file = state.entries[path];
  const currentActiveFile = getters.activeFile;

  if (file.active) return;

  if (currentActiveFile) {
    commit(types.SET_FILE_ACTIVE, {
      path: currentActiveFile.path,
      active: false,
    });
  }

  commit(types.SET_FILE_ACTIVE, { path, active: true });
  dispatch('scrollToTab');

  commit(types.SET_CURRENT_PROJECT, file.projectId);
  commit(types.SET_CURRENT_BRANCH, file.branchId);
};

export const getFileData = ({ state, commit, dispatch }, { path, makeFileActive = true }) => {
  const file = state.entries[path];
  commit(types.TOGGLE_LOADING, { entry: file });
  return service
    .getFileData(file.url)
    .then(res => {
      const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);

      setPageTitle(pageTitle);

      return res.json();
    })
    .then(data => {
      commit(types.SET_FILE_DATA, { data, file });
      commit(types.TOGGLE_FILE_OPEN, path);
      if (makeFileActive) dispatch('setFileActive', file.path);
      commit(types.TOGGLE_LOADING, { entry: file });
    })
    .catch(() => {
      commit(types.TOGGLE_LOADING, { entry: file });
      flash('Error loading file data. Please try again.', 'alert', document, null, false, true);
    });
};

export const setFileMrChange = ({ state, commit }, { file, mrChange }) => {
  commit(types.SET_FILE_MR_CHANGE, { file, mrChange });
};

export const getRawFileData = ({ state, commit, dispatch }, { path, baseSha }) => {
  const file = state.entries[path];
  return new Promise((resolve, reject) => {
    service
      .getRawFileData(file)
      .then(raw => {
        commit(types.SET_FILE_RAW_DATA, { file, raw });
        if (file.mrChange && file.mrChange.new_file === false) {
          service
            .getBaseRawFileData(file, baseSha)
            .then(baseRaw => {
              commit(types.SET_FILE_BASE_RAW_DATA, {
                file,
                baseRaw,
              });
              resolve(raw);
            })
            .catch(e => {
              reject(e);
            });
        } else {
          resolve(raw);
        }
      })
      .catch(() => {
        flash('Error loading file content. Please try again.');
        reject();
      });
  });
};

export const changeFileContent = ({ state, commit }, { path, content }) => {
  const file = state.entries[path];
  commit(types.UPDATE_FILE_CONTENT, { path, content });

  const indexOfChangedFile = state.changedFiles.findIndex(f => f.path === path);

  if (file.changed && indexOfChangedFile === -1) {
    commit(types.ADD_FILE_TO_CHANGED, path);
  } else if (!file.changed && indexOfChangedFile !== -1) {
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
    commit(types.SET_FILE_POSITION, {
      file: getters.activeFile,
      editorRow,
      editorColumn,
    });
  }
};

export const discardFileChanges = ({ state, commit }, path) => {
  const file = state.entries[path];

  commit(types.DISCARD_FILE_CHANGES, path);
  commit(types.REMOVE_FILE_FROM_CHANGED, path);

  if (file.tempFile && file.opened) {
    commit(types.TOGGLE_FILE_OPEN, path);
  }

  eventHub.$emit(`editor.update.model.content.${file.path}`, file.raw);
};
