import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_PROJECT](state, currentProjectId) {
    Object.assign(state, {
      currentProjectId,
    });
  },
  [types.SET_PROJECT](state, { projectPath, project }) {
    // Add client side properties
    Object.assign(project, {
      tree: [],
      branches: {},
      mergeRequests: {},
      active: true,
    });

    Object.assign(state, {
      projects: Object.assign({}, state.projects, {
        [projectPath]: project,
      }),
    });
  },
};
