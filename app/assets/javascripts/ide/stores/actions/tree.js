import { normalizeHeaders } from '../../../lib/utils/common_utils';
import flash from '../../../flash';
import service from '../../services';
import * as types from '../mutation_types';
import {
  pushState,
  setPageTitle,
  findEntry,
  createTemp,
  createOrMergeEntry,
} from '../utils';
import router from '../../ide_router';

export const getTreeData = (
  { commit, state, dispatch },
  { endpoint = state.endpoints.rootEndpoint, tree = null, namespace, projectId, branch } = {},
) => new Promise((resolve, reject) => {
  // We already have the base tree so we resolve immediately
  if (!tree && state.trees[`${namespace}/${projectId}/${branch}`]) {
    resolve();
  } else {
    if (tree) commit(types.TOGGLE_LOADING, tree);
    service.getTreeData(endpoint)
      .then((res) => {
        const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);
  
        setPageTitle(pageTitle);
  
        return res.json();
      })
      .then((data) => {
        if (!state.isInitialRoot) {
          commit(types.SET_ROOT, data.path === '/');
        }
  
        dispatch('updateDirectoryData', { data, tree, namespace, projectId, branch });
        if (!tree) {
          // If there was no tree given one was just created
          tree = state.trees[`${namespace}/${projectId}/${branch}`];
        }
  
        commit(types.SET_PARENT_TREE_URL, data.parent_tree_url);
        commit(types.SET_LAST_COMMIT_URL, { tree, url: data.last_commit_path });
        if (tree) commit(types.TOGGLE_LOADING, tree);
  
        const prevLastCommitPath = tree.lastCommitPath;
        if (prevLastCommitPath !== null) {
          dispatch('getLastCommitData', tree);
        }
        console.log('Loaded Tree');
        resolve(data);
      })
      .catch((e) => {
        flash('Error loading tree data. Please try again.');
        if (tree) commit(types.TOGGLE_LOADING, tree);
        reject(e);
      });
  }
});

export const toggleTreeOpen = ({ commit, dispatch }, { endpoint, tree }) => {
  if (tree.opened) {
    // send empty data to clear the tree
    const data = { trees: [], blobs: [], submodules: [] };

    pushState(tree.parentTreeUrl);

    commit(types.SET_PREVIOUS_URL, tree.parentTreeUrl);
    dispatch('updateDirectoryData', { data, tree });
  } else {
    commit(types.SET_PREVIOUS_URL, endpoint);
    dispatch('getTreeData', { endpoint, tree });
  }

  commit(types.TOGGLE_TREE_OPEN, tree);
};

export const handleTreeEntryAction = ({ commit, dispatch }, row) => {
  if (row.type === 'tree') {
    dispatch('toggleTreeOpen', {
      endpoint: row.url,
      tree: row,
    });
  } else if (row.type === 'submodule') {
    commit(types.TOGGLE_LOADING, row);
    gl.utils.visitUrl(row.url);
  } else if (row.type === 'blob' && row.opened) {
    dispatch('setFileActive', row);
  } else {
    dispatch('getFileData', row);
  }
};

export const createTempTree = ({ state, commit, dispatch }, name) => {
  let tree = state;
  const dirNames = name.replace(new RegExp(`^${state.path}/`), '').split('/');

  dirNames.forEach((dirName) => {
    const foundEntry = findEntry(tree, 'tree', dirName);

    if (!foundEntry) {
      const tmpEntry = createTemp({
        name: dirName,
        path: tree.path,
        type: 'tree',
        level: tree.level !== undefined ? tree.level + 1 : 0,
      });

      commit(types.CREATE_TMP_TREE, {
        parent: tree,
        tmpEntry,
      });
      commit(types.TOGGLE_TREE_OPEN, tmpEntry);

      tree = tmpEntry;
    } else {
      tree = foundEntry;
    }
  });

  if (tree.tempFile) {
    dispatch('createTempFile', {
      tree,
      name: '.gitkeep',
    });
  }
};

export const getLastCommitData = ({ state, commit, dispatch, getters }, tree = state) => {
  if (tree.lastCommitPath === null || getters.isCollapsed) return;

  service.getTreeLastCommit(tree.lastCommitPath)
    .then((res) => {
      const lastCommitPath = normalizeHeaders(res.headers)['MORE-LOGS-URL'] || null;

      commit(types.SET_LAST_COMMIT_URL, { tree, url: lastCommitPath });

      return res.json();
    })
    .then((data) => {
      data.forEach((lastCommit) => {
        const entry = findEntry(tree, lastCommit.type, lastCommit.file_name);

        if (entry) {
          commit(types.SET_LAST_COMMIT_DATA, { entry, lastCommit });
        }
      });

      dispatch('getLastCommitData', tree);
    })
    .catch(() => flash('Error fetching log data.'));
};

export const updateDirectoryData = (
  { commit, state },
  { data, tree, namespace, projectId, branch }
) => {
  if (!tree) {
    const existingTree = state.trees[`${namespace}/${projectId}/${branch}`];
    if (!existingTree) {
      commit(types.CREATE_TREE, { treePath: `${namespace}/${projectId}/${branch}` });
      tree = state.trees[`${namespace}/${projectId}/${branch}`];
    }
  }

  const level = tree.level !== undefined ? tree.level + 1 : 0;
  const parentTreeUrl = data.parent_tree_url ? `${data.parent_tree_url}${data.path}` : state.endpoints.rootUrl;
  const createEntry = (entry, type) => createOrMergeEntry({
    tree,
    entry,
    level,
    type,
    parentTreeUrl,
  });

  const formattedData = [
    ...data.trees.map(t => createEntry(t, 'tree')),
    ...data.submodules.map(m => createEntry(m, 'submodule')),
    ...data.blobs.map(b => createEntry(b, 'blob')),
  ];

  commit(types.SET_DIRECTORY_DATA, { tree, data: formattedData });
};
