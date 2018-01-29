import service from '../../services';
import flash from '../../../flash';
import * as types from '../mutation_types';

export const getBranchData = (
  { commit, state, dispatch },
  { projectId, branchId, force = false } = {},
) => new Promise((resolve, reject) => {
  if ((typeof state.projects[`${projectId}`] === 'undefined' ||
        !state.projects[`${projectId}`].branches[branchId])
        || force) {
    service.getBranchData(`${projectId}`, branchId)
      .then((data) => {
        const { id } = data.commit;
        commit(types.SET_BRANCH, { projectPath: `${projectId}`, branchName: branchId, branch: data });
        commit(types.SET_BRANCH_WORKING_REFERENCE, { projectId, branchId, reference: id });
        resolve(data);
      })
      .catch(() => {
        flash('Error loading branch data. Please try again.', 'alert', document, null, false, true);
        reject(new Error(`Branch not loaded - ${projectId}/${branchId}`));
      });
  } else {
    resolve(state.projects[`${projectId}`].branches[branchId]);
  }
});

export const createNewBranch = ({ state, commit }, branch) => service.createBranch(
  state.currentProjectId,
  {
    branch,
    ref: state.currentBranchId,
  },
)
.then(res => res.json())
.then((data) => {
  const branchName = data.name;
  const url = location.href.replace(state.currentBranchId, branchName);

  if (this.$router) this.$router.push(url);

  commit(types.SET_CURRENT_BRANCH, branchName);
});
