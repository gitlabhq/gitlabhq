import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_BRANCH](state, currentBranchId) {
    Object.assign(state, {
      currentBranchId,
    });
  },
  [types.SET_BRANCH](state, { projectPath, branchName, branch }) {
    Object.assign(state.projects[projectPath], {
      branches: {
        [branchName]: {
          ...branch,
          treeId: `${projectPath}/${branchName}`,
          active: true,
          workingReference: '',
          commit: {
            ...branch.commit,
            pipeline: {},
          },
        },
      },
    });
  },
  [types.SET_BRANCH_WORKING_REFERENCE](state, { projectId, branchId, reference }) {
    Object.assign(state.projects[projectId].branches[branchId], {
      workingReference: reference,
    });
  },
  [types.SET_BRANCH_COMMIT](state, { projectId, branchId, commit }) {
    Object.assign(state.projects[projectId].branches[branchId], {
      commit,
    });
  },
  [types.SET_LAST_COMMIT_PIPELINE](state, { projectId, branchId, pipeline }) {
    Object.assign(state.projects[projectId].branches[branchId].commit, {
      pipeline,
    });
  },
};
