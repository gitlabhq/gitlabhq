import service from '../../services';
import * as types from '../mutation_types';
import { pushState } from '../utils';

// eslint-disable-next-line import/prefer-default-export
export const createNewBranch = ({ rootState, commit }, branch) => service.createBranch(
  rootState.project.id,
  {
    branch,
    ref: rootState.currentBranch,
  },
).then(res => res.json())
.then((data) => {
  const branchName = data.name;
  const url = location.href.replace(rootState.currentBranch, branchName);

  pushState(url);

  commit(types.SET_CURRENT_BRANCH, branchName);
});
