import service from '../../services';
import flash from '../../../flash';
import * as types from '../mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const getBranchData = (
  { commit, state, dispatch },
  { projectId, branchId, enforce = false } = {},
) => new Promise((resolve, reject) => {
  if ((typeof state.projects[`${projectId}`] === 'undefined' ||
        !state.projects[`${projectId}`].branches[branchId])
        || enforce) {
    service.getBranchData(`${projectId}`, branchId)
      .then((data) => {
        commit(types.SET_BRANCH, { projectPath: `${projectId}`, branchName: branchId, branch: data });
        dispatch('setBranchReference', { projectId, branchId });
        resolve(data);
      })
      .catch(() => {
        flash('Error loading branch data. Please try again.');
        reject(new Error('Branch not loaded'));
      });
  } else {
    resolve(state.projects[`${projectId}`].branches[branchId]);
  }
});

export const setBranchReference = ({ commit, state }, { projectId, branchId }) =>
  service.getBranchData(
    projectId,
    branchId,
  )
  .then((data) => {
    const { id } = data.commit;
    commit(types.SET_BRANCH_WORKING_REFERENCE, { projectId, branchId, reference: id });
  })
  .catch(() => flash('Error checking branch data. Please try again.'));

// eslint-disable-next-line import/prefer-default-export
export const createNewBranch = ({ state, commit }, branch) => service.createBranch(
  state.project.id,
  {
    branch,
    ref: state.currentBranchId,
  },
)
.then(res => res.json())
.then((data) => {
  const branchName = data.name;
  const url = location.href.replace(state.currentBranchId, branchName);

  this.$router.push(url);

  commit(types.SET_CURRENT_BRANCH, branchName);
});
