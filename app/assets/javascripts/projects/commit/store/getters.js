import { uniq } from 'lodash';

export const joinedBranches = (state) => {
  return uniq(state.branches).sort();
};

export const sortedProjects = (state) => uniq(state.projects).sort();
