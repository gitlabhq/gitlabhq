import { uniq } from 'lodash';

export const joinedBranches = (state) => {
  return uniq(state.branches).sort();
};
