import * as types from '../mutation_types';

export default {
  [types.SET_PROJECT](state, { projectPath, project }) {
    Object.assign(project, {
      tree: [],
      active: true,
    });
    Object.assign(state.projects, {
      [projectPath]: project,
    });
  },
};
