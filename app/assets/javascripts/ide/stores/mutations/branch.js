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
      treeId: `${projectPath}/${branchName}`,
      active: true,
      workingReference: '',
    });

    Object.assign(state.projects[projectPath], {
      branches: {
        [branchName]: branch,
      },
    });
  },
  [types.SET_BRANCH_WORKING_REFERENCE](state, { projectId, branchId, reference }) {
    Object.assign(state.projects[projectId].branches[branchId], {
      workingReference: reference,
    });
  },
};
