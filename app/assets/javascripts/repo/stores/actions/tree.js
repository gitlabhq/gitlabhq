import { normalizeHeaders } from '../../../lib/utils/common_utils';
import flash from '../../../flash';
import service from '../../services';
import * as types from '../mutation_types';
import {
  pushState,
  setPageTitle,
  findEntry,
  createTemp,
} from '../utils';

export const getTreeData = (
  { commit, state },
  { endpoint = state.endpoints.rootEndpoint, tree = state } = {},
) => {
  commit(types.TOGGLE_LOADING, tree);

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

      commit(types.SET_DIRECTORY_DATA, { data, tree });
      commit(types.SET_PARENT_TREE_URL, data.parent_tree_url);
      commit(types.TOGGLE_LOADING, tree);

      pushState(endpoint);
    })
    .catch(() => {
      flash('Error loading tree data. Please try again.');
      commit(types.TOGGLE_LOADING, tree);
    });
};

export const toggleTreeOpen = ({ commit, dispatch }, { endpoint, tree }) => {
  if (tree.opened) {
    // send empty data to clear the tree
    const data = { trees: [], blobs: [], submodules: [] };

    pushState(tree.parentTreeUrl);

    commit(types.SET_PREVIOUS_URL, tree.parentTreeUrl);
    commit(types.SET_DIRECTORY_DATA, { data, tree });
  } else {
    commit(types.SET_PREVIOUS_URL, endpoint);
    dispatch('getTreeData', { endpoint, tree });
  }

  commit(types.TOGGLE_TREE_OPEN, tree);
};

export const clickedTreeRow = ({ commit, dispatch }, row) => {
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
