import { uniq, uniqBy } from 'lodash';

export const joinedBranches = (state) => {
  return uniq(state.branches).sort();
};

export const sortedProjects = (state) => uniqBy(state.projects, 'id').sort();
