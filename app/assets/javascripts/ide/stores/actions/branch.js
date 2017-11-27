import service from '../../services';
import flash from '../../../flash';
import * as types from '../mutation_types';
import { pushState } from '../utils';

// eslint-disable-next-line import/prefer-default-export
export const getBranchData = (
  { commit, state, dispatch },
  { namespace, projectId, branch, enforce = false } = {},
) => new Promise((resolve, reject) => {
  if ((typeof state.projects[`${namespace}/${projectId}`] === 'undefined' ||
        !state.projects[`${namespace}/${projectId}`].branches[branch])
        || enforce) {
    console.log('Loading Branch ' + branch);
    service.getBranchData(`${namespace}/${projectId}`, branch)
      .then((data) => {
        commit(types.SET_BRANCH, { projectPath: `${namespace}/${projectId}`, branchName: branch, branch: data });
        resolve(data);
      })
      .catch(() => {
        flash('Error loading branch data. Please try again.');
        reject(new Error('Branch not loaded'));
      });
  } else {
    resolve(state.projects[`${namespace}/${projectId}`].branches[branch]);
  }
});

// eslint-disable-next-line import/prefer-default-export
export const createNewBranch = ({ state, commit }, branch) => service.createBranch(
  state.project.id,
  {
    branch,
    ref: state.currentBranch,
  },
)
.then(res => res.json())
.then((data) => {
  const branchName = data.name;
  const url = location.href.replace(state.currentBranch, branchName);

  pushState(url);

  commit(types.SET_CURRENT_BRANCH, branchName);
});
