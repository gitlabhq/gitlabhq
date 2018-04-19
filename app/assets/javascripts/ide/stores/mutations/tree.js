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
    Object.assign(state.trees[treePath], {
      tree: data,
    });
  },
  [types.SET_LAST_COMMIT_URL](state, { tree = state, url }) {
    Object.assign(tree, {
      lastCommitPath: url,
    });
  },
  [types.REMOVE_ALL_CHANGES_FILES](state) {
    Object.assign(state, {
      changedFiles: [],
    });
  },
};
