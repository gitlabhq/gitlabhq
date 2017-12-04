import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_BRANCH](state, currentBranchId) {
    Object.assign(state, {
      currentBranchId,
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

    Object.assign(state.projects, Object.assign({}, state.projects, {
      [projectPath]: state.projects[projectPath],
    }));
  },
};
