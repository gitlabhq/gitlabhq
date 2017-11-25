import * as types from '../mutation_types';

export default {
  [types.SET_PROJECT](state, { projectPath, project }) {
    // Add client side properties
    Object.assign(project, {
      tree: [],
      branches: {},
      active: true,
    });

    Object.assign(state, {
      projects: {
        [projectPath]: project,
      },
    });
  },
};
