import { normalizeHeaders } from '~/lib/utils/common_utils';
import flash from '~/flash';
import service from '../../services';
import * as types from '../mutation_types';
import {
  findEntry,
} from '../utils';
import FilesDecoratorWorker from '../workers/files_decorator_worker';

export const toggleTreeOpen = ({ commit, dispatch }, path) => {
  commit(types.TOGGLE_TREE_OPEN, path);
};

export const handleTreeEntryAction = ({ commit, dispatch }, row) => {
  if (row.type === 'tree') {
    dispatch('toggleTreeOpen', row.path);
  } else if (row.type === 'blob' && (row.opened || row.changed)) {
    if (row.changed && !row.opened) {
      commit(types.TOGGLE_FILE_OPEN, row.path);
    }

    dispatch('setFileActive', row.path);
  } else {
    dispatch('getFileData', row);
  }
};

export const getLastCommitData = ({ state, commit, dispatch, getters }, tree = state) => {
  if (!tree || tree.lastCommitPath === null || !tree.lastCommitPath) return;

  service.getTreeLastCommit(tree.lastCommitPath)
    .then((res) => {
      const lastCommitPath = normalizeHeaders(res.headers)['MORE-LOGS-URL'] || null;

      commit(types.SET_LAST_COMMIT_URL, { tree, url: lastCommitPath });

      return res.json();
    })
    .then((data) => {
      data.forEach((lastCommit) => {
        const entry = findEntry(tree.tree, lastCommit.type, lastCommit.file_name);

        if (entry) {
          commit(types.SET_LAST_COMMIT_DATA, { entry, lastCommit });
        }
      });

      dispatch('getLastCommitData', tree);
    })
    .catch(() => flash('Error fetching log data.', 'alert', document, null, false, true));
};

export const getFiles = (
  { state, commit, dispatch },
  { projectId, branchId } = {},
) => new Promise((resolve, reject) => {
  if (!state.trees[`${projectId}/${branchId}`]) {
    const selectedProject = state.projects[projectId];
    commit(types.CREATE_TREE, { treePath: `${projectId}/${branchId}` });

    service
      .getFiles(selectedProject.web_url, branchId)
      .then(res => res.json())
      .then((data) => {
        const worker = new FilesDecoratorWorker();
        worker.addEventListener('message', (e) => {
          const { entries, treeList } = e.data;
          const selectedTree = state.trees[`${projectId}/${branchId}`];

          commit(types.SET_ENTRIES, entries);
          commit(types.SET_DIRECTORY_DATA, { treePath: `${projectId}/${branchId}`, data: treeList });
          commit(types.TOGGLE_LOADING, { entry: selectedTree, forceValue: false });

          worker.terminate();

          resolve();
        });

        worker.postMessage({
          data,
          projectId,
          branchId,
        });
      })
      .catch((e) => {
        flash('Error loading tree data. Please try again.', 'alert', document, null, false, true);
        reject(e);
      });
  } else {
    resolve();
  }
});

