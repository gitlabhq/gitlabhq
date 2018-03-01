import * as types from '../mutation_types';

export default {
  [types.TOGGLE_TREE_OPEN](state, tree) {
    Object.assign(tree, {
      opened: !tree.opened,
    });
  },
  [types.CREATE_TREE](state, { treePath }) {
    Object.assign(state, {
      trees: Object.assign({}, state.trees, {
        [treePath]: {
          tree: [],
        },
      }),
    });
  },
  [types.SET_DIRECTORY_DATA](state, { data, tree }) {
    Object.assign(tree, {
      tree: data,
    });
  },
  [types.SET_PARENT_TREE_URL](state, url) {
    Object.assign(state, {
      parentTreeUrl: url,
    });
  },
  [types.SET_LAST_COMMIT_URL](state, { tree = state, url }) {
    Object.assign(tree, {
      lastCommitPath: url,
    });
  },
  [types.CREATE_TMP_TREE](state, { parent, tmpEntry }) {
    parent.tree.push(tmpEntry);
  },
  [types.REMOVE_ALL_CHANGES_FILES](state) {
    Object.assign(state, {
      changedFiles: [],
    });
  },
};
