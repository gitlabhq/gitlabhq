import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  WEBIDE_MARK_FETCH_FILE_DATA_START,
  WEBIDE_MARK_FETCH_FILE_DATA_FINISH,
  WEBIDE_MEASURE_FETCH_FILE_DATA,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';
import { viewerTypes, stageKeys, commitActionTypes } from '../../constants';
import eventHub from '../../eventhub';
import service from '../../services';
import * as types from '../mutation_types';
import { setPageTitleForFile } from '../utils';

export const closeFile = ({ commit, state, dispatch, getters }, file) => {
  const { path } = file;
  const indexOfClosedFile = state.openFiles.findIndex((f) => f.key === file.key);
  const fileWasActive = file.active;

  if (state.openFiles.length > 1 && fileWasActive) {
    const nextIndexToOpen = indexOfClosedFile === 0 ? 1 : indexOfClosedFile - 1;
    const nextFileToOpen = state.openFiles[nextIndexToOpen];

    if (nextFileToOpen.pending) {
      dispatch('updateViewer', viewerTypes.diff);
      dispatch('openPendingTab', {
        file: nextFileToOpen,
        keyPrefix: nextFileToOpen.staged ? 'staged' : 'unstaged',
      });
    } else {
      dispatch('setFileActive', nextFileToOpen.path);
      dispatch('router/push', getters.getUrlForPath(nextFileToOpen.path), { root: true });
    }
  } else if (state.openFiles.length === 1) {
    dispatch('router/push', `/project/${state.currentProjectId}/tree/${state.currentBranchId}/`, {
      root: true,
    });
  }

  if (file.pending) {
    commit(types.REMOVE_PENDING_TAB, file);
  } else {
    commit(types.TOGGLE_FILE_OPEN, path);
    commit(types.SET_FILE_ACTIVE, { path, active: false });
  }

  eventHub.$emit(`editor.update.model.dispose.${file.key}`);
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
};

export const getFileData = (
  { state, commit, dispatch, getters },
  { path, makeFileActive = true, openFile = makeFileActive, toggleLoading = true },
) => {
  performanceMarkAndMeasure({ mark: WEBIDE_MARK_FETCH_FILE_DATA_START });
  const file = state.entries[path];
  const fileDeletedAndReadded = getters.isFileDeletedAndReadded(path);

  if (file.raw || (file.tempFile && !file.prevPath && !fileDeletedAndReadded))
    return Promise.resolve();

  commit(types.TOGGLE_LOADING, { entry: file, forceValue: true });

  const url = joinPaths(
    gon.relative_url_root || '/',
    state.currentProjectId,
    '-',
    file.type,
    getters.lastCommit && getters.lastCommit.id,
    escapeFileUrl(file.prevPath || file.path),
  );

  return service
    .getFileData(url)
    .then(({ data }) => {
      performanceMarkAndMeasure({
        mark: WEBIDE_MARK_FETCH_FILE_DATA_FINISH,
        measures: [
          {
            name: WEBIDE_MEASURE_FETCH_FILE_DATA,
            start: WEBIDE_MARK_FETCH_FILE_DATA_START,
          },
        ],
      });
      if (data) commit(types.SET_FILE_DATA, { data, file });
      if (openFile) commit(types.TOGGLE_FILE_OPEN, path);

      if (makeFileActive) {
        setPageTitleForFile(state, file);
        dispatch('setFileActive', path);
      }
    })
    .catch(() => {
      dispatch('setErrorMessage', {
        text: __('An error occurred while loading the file.'),
        action: (payload) =>
          dispatch('getFileData', payload).then(() => dispatch('setErrorMessage', null)),
        actionText: __('Please try again'),
        actionPayload: { path, makeFileActive },
      });
    })
    .finally(() => {
      if (toggleLoading) commit(types.TOGGLE_LOADING, { entry: file, forceValue: false });
    });
};

export const getRawFileData = ({ state, commit, dispatch, getters }, { path }) => {
  const file = state.entries[path];
  const stagedFile = state.stagedFiles.find((f) => f.path === path);

  const fileDeletedAndReadded = getters.isFileDeletedAndReadded(path);
  commit(types.TOGGLE_LOADING, { entry: file, forceValue: true });
  return service
    .getRawFileData(fileDeletedAndReadded ? stagedFile : file)
    .then((raw) => {
      if (!(file.tempFile && !file.prevPath && !fileDeletedAndReadded))
        commit(types.SET_FILE_RAW_DATA, { file, raw, fileDeletedAndReadded });

      if (file.mrChange && file.mrChange.new_file === false) {
        const baseSha =
          (getters.currentMergeRequest && getters.currentMergeRequest.baseCommitSha) || '';

        return service.getBaseRawFileData(file, state.currentProjectId, baseSha).then((baseRaw) => {
          commit(types.SET_FILE_BASE_RAW_DATA, {
            file,
            baseRaw,
          });
          return raw;
        });
      }
      return raw;
    })
    .catch((e) => {
      dispatch('setErrorMessage', {
        text: __('An error occurred while loading the file content.'),
        action: (payload) =>
          dispatch('getRawFileData', payload).then(() => dispatch('setErrorMessage', null)),
        actionText: __('Please try again'),
        actionPayload: { path },
      });
      throw e;
    })
    .finally(() => {
      commit(types.TOGGLE_LOADING, { entry: file, forceValue: false });
    });
};

export const changeFileContent = ({ commit, dispatch, state, getters }, { path, content }) => {
  const file = state.entries[path];

  // It's possible for monaco to hit a race condition where it tries to update renamed files.
  // See issue https://gitlab.com/gitlab-org/gitlab/-/issues/284930
  if (!file) {
    return;
  }

  commit(types.UPDATE_FILE_CONTENT, {
    path,
    content,
  });

  const indexOfChangedFile = state.changedFiles.findIndex((f) => f.path === path);

  if (file.changed && indexOfChangedFile === -1) {
    commit(types.STAGE_CHANGE, { path, diffInfo: getters.getDiffInfo(path) });
  } else if (!file.changed && !file.tempFile && indexOfChangedFile !== -1) {
    commit(types.REMOVE_FILE_FROM_CHANGED, path);
  }

  dispatch('triggerFilesChange', { type: commitActionTypes.update, path });
};

export const restoreOriginalFile = ({ dispatch, state, commit }, path) => {
  const file = state.entries[path];
  const isDestructiveDiscard = file.tempFile || file.prevPath;

  if (file.deleted && file.parentPath) {
    dispatch('restoreTree', file.parentPath);
  }

  if (isDestructiveDiscard) {
    dispatch('closeFile', file);
  }

  if (file.tempFile) {
    dispatch('deleteEntry', file.path);
  } else {
    commit(types.DISCARD_FILE_CHANGES, file.path);
  }

  if (file.prevPath) {
    dispatch('renameEntry', {
      path: file.path,
      name: file.prevName,
      parentPath: file.prevParentPath,
    });
  }
};

export const discardFileChanges = ({ dispatch, state, commit, getters }, path) => {
  const file = state.entries[path];
  const isDestructiveDiscard = file.tempFile || file.prevPath;

  dispatch('restoreOriginalFile', path);

  if (!isDestructiveDiscard && file.path === getters.activeFile?.path) {
    dispatch('updateDelayViewerUpdated', true)
      .then(() => {
        dispatch('router/push', getters.getUrlForPath(file.path), { root: true });
      })
      .catch((e) => {
        throw e;
      });
  }

  commit(types.REMOVE_FILE_FROM_CHANGED, path);

  eventHub.$emit(`editor.update.model.new.content.${file.key}`, file.content);
  eventHub.$emit(`editor.update.model.dispose.unstaged-${file.key}`, file.content);
};

export const stageChange = ({ commit, dispatch, getters }, path) => {
  const stagedFile = getters.getStagedFile(path);
  const openFile = getters.getOpenFile(path);

  commit(types.STAGE_CHANGE, { path, diffInfo: getters.getDiffInfo(path) });
  commit(types.SET_LAST_COMMIT_MSG, '');

  if (stagedFile) {
    eventHub.$emit(`editor.update.model.new.content.staged-${stagedFile.key}`, stagedFile.content);
  }

  const file = getters.getStagedFile(path);

  if (openFile && openFile.active && file) {
    dispatch('openPendingTab', {
      file,
      keyPrefix: stageKeys.staged,
    });
  }
};

export const unstageChange = ({ commit, dispatch, getters }, path) => {
  const openFile = getters.getOpenFile(path);

  commit(types.UNSTAGE_CHANGE, { path, diffInfo: getters.getDiffInfo(path) });

  const file = getters.getChangedFile(path);

  if (openFile && openFile.active && file) {
    dispatch('openPendingTab', {
      file,
      keyPrefix: stageKeys.unstaged,
    });
  }
};

export const openPendingTab = ({ commit, dispatch, getters, state }, { file, keyPrefix }) => {
  if (getters.activeFile && getters.activeFile.key === `${keyPrefix}-${file.key}`) return false;

  state.openFiles.forEach((f) => eventHub.$emit(`editor.update.model.dispose.${f.key}`));

  commit(types.ADD_PENDING_TAB, { file, keyPrefix });

  dispatch('router/push', `/project/${state.currentProjectId}/tree/${state.currentBranchId}/`, {
    root: true,
  });

  return true;
};

export const removePendingTab = ({ commit }, file) => {
  commit(types.REMOVE_PENDING_TAB, file);

  eventHub.$emit(`editor.update.model.dispose.${file.key}`);
};

export const triggerFilesChange = (ctx, payload = {}) => {
  // Used in EE for file mirroring
  eventHub.$emit('ide.files.change', payload);
};
