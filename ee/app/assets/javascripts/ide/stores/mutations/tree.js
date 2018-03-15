import * as types from '../mutation_types';

export default {
  [types.TOGGLE_TREE_OPEN](state, path) {
    Object.assign(state.entries[path], {
      opened: !state.entries[path].opened,
    });
  },
  [types.CREATE_TREE](state, { treePath }) {
    Object.assign(state, {
      trees: Object.assign({}, state.trees, {
        [treePath]: {
          tree: [],
          loading: true,
        },
      }),
    });
  },
  [types.SET_DIRECTORY_DATA](state, { data, treePath }) {
    Object.assign(state, {
      trees: Object.assign(state.trees, {
        [treePath]: {
          tree: data,
        },
      }),
    });
  },
  [types.SET_LAST_COMMIT_URL](state, { tree = state, url }) {
    Object.assign(tree, {
      lastCommitPath: url,
    });
  },
  [types.CREATE_TMP_TREE](state, { data, projectId, branchId }) {
    Object.keys(data.entries).forEach((key) => {
      const entry = data.entries[key];

      Object.assign(state.entries, {
        [key]: entry,
      });
    });

    Object.assign(state.trees[`${projectId}/${branchId}`], {
      tree: state.trees[`${projectId}/${branchId}`].tree.concat(data.treeList),
    });
  },
  [types.REMOVE_ALL_CHANGES_FILES](state) {
    Object.assign(state, {
      changedFiles: [],
    });
  },
};
