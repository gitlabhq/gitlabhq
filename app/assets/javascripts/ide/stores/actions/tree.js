import { __ } from '../../../locale';
import service from '../../services';
import * as types from '../mutation_types';
import FilesDecoratorWorker from '../workers/files_decorator_worker';

export const toggleTreeOpen = ({ commit }, path) => {
  commit(types.TOGGLE_TREE_OPEN, path);
};

export const showTreeEntry = ({ commit, dispatch, state }, path) => {
  const entry = state.entries[path];
  const parentPath = entry ? entry.parentPath : '';

  if (parentPath) {
    commit(types.SET_TREE_OPEN, parentPath);

    dispatch('showTreeEntry', parentPath);
  }
};

export const handleTreeEntryAction = ({ commit, dispatch }, row) => {
  if (row.type === 'tree') {
    dispatch('toggleTreeOpen', row.path);
  } else if (row.type === 'blob') {
    if (!row.opened) {
      commit(types.TOGGLE_FILE_OPEN, row.path);
    }

    dispatch('setFileActive', row.path);
  }

  dispatch('showTreeEntry', row.path);
};

export const getFiles = ({ state, commit, dispatch }, { projectId, branchId } = {}) =>
  new Promise((resolve, reject) => {
    if (
      !state.trees[`${projectId}/${branchId}`] ||
      (state.trees[`${projectId}/${branchId}`].tree &&
        state.trees[`${projectId}/${branchId}`].tree.length === 0)
    ) {
      const selectedProject = state.projects[projectId];
      commit(types.CREATE_TREE, { treePath: `${projectId}/${branchId}` });

      service
        .getFiles(selectedProject.web_url, branchId)
        .then(({ data }) => {
          const worker = new FilesDecoratorWorker();
          worker.addEventListener('message', e => {
            const { entries, treeList } = e.data;
            const selectedTree = state.trees[`${projectId}/${branchId}`];

            commit(types.SET_ENTRIES, entries);
            commit(types.SET_DIRECTORY_DATA, {
              treePath: `${projectId}/${branchId}`,
              data: treeList,
            });
            commit(types.TOGGLE_LOADING, {
              entry: selectedTree,
              forceValue: false,
            });

            if (entries['.gitattributes']) {
              dispatch('getFileData', { path: '.gitattributes', makeFileActive: false })
                .then(() => dispatch('getRawFileData', { path: '.gitattributes' }))
                .catch(() => {});
            }

            worker.terminate();

            resolve();
          });

          worker.postMessage({
            data,
            projectId,
            branchId,
          });
        })
        .catch(e => {
          if (e.response.status === 404) {
            dispatch('showBranchNotFoundError', branchId);
          } else {
            dispatch('setErrorMessage', {
              text: __('An error occured whilst loading all the files.'),
              action: payload =>
                dispatch('getFiles', payload).then(() => dispatch('setErrorMessage', null)),
              actionText: __('Please try again'),
              actionPayload: { projectId, branchId },
            });
          }
          reject(e);
        });
    } else {
      resolve();
    }
  });

export const restoreTree = ({ dispatch, commit, state }, path) => {
  const entry = state.entries[path];

  commit(types.RESTORE_TREE, path);

  if (entry.parentPath) {
    dispatch('restoreTree', entry.parentPath);
  }
};
