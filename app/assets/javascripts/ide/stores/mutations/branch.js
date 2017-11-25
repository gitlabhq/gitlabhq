import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_BRANCH](state, currentBranch) {
    Object.assign(state, {
      currentBranch,
    });
  },
  [types.SET_BRANCH](state, { projectPath, branchName, branch }) {
    // Add client side properties
    Object.assign(branch, {
      tree: [],
      treeId: `${projectPath}/${branchName}`,
      active: true,
    });

    Object.assign(state.projects[projectPath], {
      branches: {
        [branchName]: branch,
      },
    });

    state.projects = Object.assign({}, state.projects, {
      [projectPath]: state.projects[projectPath]
    });
  },
};
