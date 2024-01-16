import { escape } from 'lodash';
import Vue from 'vue';
import { createAlert } from '~/alert';
import { HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import {
  WEBIDE_MARK_FETCH_BRANCH_DATA_START,
  WEBIDE_MARK_FETCH_BRANCH_DATA_FINISH,
  WEBIDE_MEASURE_FETCH_BRANCH_DATA,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { stageKeys, commitActionTypes } from '../constants';
import eventHub from '../eventhub';
import { decorateFiles } from '../lib/files';
import service from '../services';
import * as types from './mutation_types';

export const redirectToUrl = (self, url) => visitUrl(url);

export const init = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const discardAllChanges = ({ state, commit, dispatch }) => {
  state.changedFiles.forEach((file) => dispatch('restoreOriginalFile', file.path));

  commit(types.REMOVE_ALL_CHANGES_FILES);
};

export const setResizingStatus = ({ commit }, resizing) => {
  commit(types.SET_RESIZING_STATUS, resizing);
};

export const createTempEntry = (
  { state, commit, dispatch, getters },
  { name, type, content = '', rawPath = '', openFile = true, makeFileActive = true, mimeType = '' },
) => {
  const fullName = name.slice(-1) !== '/' && type === 'tree' ? `${name}/` : name;

  if (getters.entryExists(name)) {
    createAlert({
      message: sprintf(__('The name "%{name}" is already taken in this directory.'), {
        name: name.split('/').pop(),
      }),
      fadeTransition: false,
      addBodyClass: true,
    });

    return undefined;
  }

  const data = decorateFiles({
    data: [fullName],
    type,
    tempFile: true,
    content,
    rawPath,
    blobData: {
      mimeType,
    },
  });
  const { file, parentPath } = data;

  commit(types.CREATE_TMP_ENTRY, { data });

  if (type === 'blob') {
    if (openFile) commit(types.TOGGLE_FILE_OPEN, file.path);
    commit(types.STAGE_CHANGE, { path: file.path, diffInfo: getters.getDiffInfo(file.path) });

    if (openFile && makeFileActive) dispatch('setFileActive', file.path);
    dispatch('triggerFilesChange');
  }

  if (parentPath && !state.entries[parentPath].opened) {
    commit(types.TOGGLE_TREE_OPEN, parentPath);
  }

  return file;
};

export const addTempImage = ({ dispatch, getters }, { name, rawPath = '', content = '' }) =>
  dispatch('createTempEntry', {
    name: getters.getAvailableFileName(name),
    type: 'blob',
    content,
    rawPath,
    openFile: false,
    makeFileActive: false,
  });

export const scrollToTab = () => {
  Vue.nextTick(() => {
    const tabs = document.getElementById('tabs');

    if (tabs) {
      const tabEl = tabs.querySelector('.active .repo-tab');

      tabEl.focus();
    }
  });
};

export const stageAllChanges = ({ state, commit, dispatch, getters }) => {
  const openFile = state.openFiles[0];

  commit(types.SET_LAST_COMMIT_MSG, '');

  state.changedFiles.forEach((file) =>
    commit(types.STAGE_CHANGE, { path: file.path, diffInfo: getters.getDiffInfo(file.path) }),
  );

  const file = getters.getStagedFile(openFile.path);

  if (file) {
    dispatch('openPendingTab', {
      file,
      keyPrefix: stageKeys.staged,
    });
  }
};

export const unstageAllChanges = ({ state, commit, dispatch, getters }) => {
  const openFile = state.openFiles[0];

  state.stagedFiles.forEach((file) =>
    commit(types.UNSTAGE_CHANGE, { path: file.path, diffInfo: getters.getDiffInfo(file.path) }),
  );

  const file = getters.getChangedFile(openFile.path);

  if (file) {
    dispatch('openPendingTab', {
      file,
      keyPrefix: stageKeys.unstaged,
    });
  }
};

export const updateViewer = ({ commit }, viewer) => {
  commit(types.UPDATE_VIEWER, viewer);
};

export const updateDelayViewerUpdated = ({ commit }, delay) => {
  commit(types.UPDATE_DELAY_VIEWER_CHANGE, delay);
};

export const updateActivityBarView = ({ commit }, view) => {
  commit(types.UPDATE_ACTIVITY_BAR_VIEW, view);
};

export const setEmptyStateSvgs = ({ commit }, svgs) => {
  commit(types.SET_EMPTY_STATE_SVGS, svgs);
};

export const setCurrentBranchId = ({ commit }, currentBranchId) => {
  commit(types.SET_CURRENT_BRANCH, currentBranchId);
};

export const updateTempFlagForEntry = ({ commit, dispatch, state }, { file, tempFile }) => {
  commit(types.UPDATE_TEMP_FLAG, { path: file.path, tempFile });

  const parent = file.parentPath && state.entries[file.parentPath];

  if (parent) {
    dispatch('updateTempFlagForEntry', { file: parent, tempFile });
  }
};

export const toggleFileFinder = ({ commit }, fileFindVisible) =>
  commit(types.TOGGLE_FILE_FINDER, fileFindVisible);

export const setLinks = ({ commit }, links) => commit(types.SET_LINKS, links);

export const setErrorMessage = ({ commit }, errorMessage) =>
  commit(types.SET_ERROR_MESSAGE, errorMessage);

export const deleteEntry = ({ commit, dispatch, state }, path) => {
  const entry = state.entries[path];
  const { prevPath, prevName, prevParentPath } = entry;
  const isTree = entry.type === 'tree';
  const prevEntry = prevPath && state.entries[prevPath];

  if (prevPath && (!prevEntry || prevEntry.deleted)) {
    dispatch('renameEntry', {
      path,
      name: prevName,
      parentPath: prevParentPath,
    });
    dispatch('deleteEntry', prevPath);
    return;
  }

  if (entry.opened) dispatch('closeFile', entry);

  if (isTree) {
    entry.tree.forEach((f) => dispatch('deleteEntry', f.path));
  }

  commit(types.DELETE_ENTRY, path);

  // Only stage if we're not a directory or a new file
  if (!isTree && !entry.tempFile) {
    dispatch('stageChange', path);
  }

  dispatch('triggerFilesChange');
};

export const resetOpenFiles = ({ commit }) => commit(types.RESET_OPEN_FILES);

export const renameEntry = ({ dispatch, commit, state, getters }, { path, name, parentPath }) => {
  const entry = state.entries[path];
  const newPath = parentPath ? `${parentPath}/${name}` : name;
  const existingParent = parentPath && state.entries[parentPath];

  if (parentPath && (!existingParent || existingParent.deleted)) {
    dispatch('createTempEntry', { name: parentPath, type: 'tree' });
  }

  commit(types.RENAME_ENTRY, { path, name, parentPath });

  if (entry.type === 'tree') {
    state.entries[newPath].tree.forEach((f) => {
      dispatch('renameEntry', {
        path: f.path,
        name: f.name,
        parentPath: newPath,
      });
    });
  } else {
    const newEntry = state.entries[newPath];
    const isRevert = newPath === entry.prevPath;
    const isReset = isRevert && !newEntry.changed && !newEntry.tempFile;
    const isInChanges = state.changedFiles
      .concat(state.stagedFiles)
      .some(({ key }) => key === newEntry.key);

    if (isReset) {
      commit(types.REMOVE_FILE_FROM_STAGED_AND_CHANGED, newEntry);
    } else if (!isInChanges) {
      commit(types.STAGE_CHANGE, { path: newPath, diffInfo: getters.getDiffInfo(newPath) });
    }

    if (!newEntry.tempFile) {
      eventHub.$emit(`editor.update.model.dispose.${entry.key}`);
    }

    if (newEntry.opened) {
      dispatch('router/push', getters.getUrlForPath(newEntry.path), { root: true });
    }
  }

  dispatch('triggerFilesChange', { type: commitActionTypes.move, path, newPath });
};

export const getBranchData = ({ commit, state }, { projectId, branchId, force = false } = {}) => {
  return new Promise((resolve, reject) => {
    performanceMarkAndMeasure({ mark: WEBIDE_MARK_FETCH_BRANCH_DATA_START });
    const currentProject = state.projects[projectId];
    if (!currentProject || !currentProject.branches[branchId] || force) {
      service
        .getBranchData(projectId, branchId)
        .then(({ data }) => {
          performanceMarkAndMeasure({
            mark: WEBIDE_MARK_FETCH_BRANCH_DATA_FINISH,
            measures: [
              {
                name: WEBIDE_MEASURE_FETCH_BRANCH_DATA,
                start: WEBIDE_MARK_FETCH_BRANCH_DATA_START,
              },
            ],
          });
          const { id } = data.commit;
          commit(types.SET_BRANCH, {
            projectPath: projectId,
            branchName: branchId,
            branch: data,
          });
          commit(types.SET_BRANCH_WORKING_REFERENCE, { projectId, branchId, reference: id });
          resolve(data);
        })
        .catch((e) => {
          if (e.response.status === HTTP_STATUS_NOT_FOUND) {
            reject(e);
          } else {
            createAlert({
              message: __('Error loading branch data. Please try again.'),
              fadeTransition: false,
              addBodyClass: true,
            });

            reject(
              new Error(
                sprintf(
                  __('Branch not loaded - %{branchId}'),
                  {
                    branchId: `<strong>${escape(projectId)}/${escape(branchId)}</strong>`,
                  },
                  false,
                ),
              ),
            );
          }
        });
    } else {
      resolve(currentProject.branches[branchId]);
    }
  });
};

export * from './actions/tree';
export * from './actions/file';
export * from './actions/project';
export * from './actions/merge_request';
