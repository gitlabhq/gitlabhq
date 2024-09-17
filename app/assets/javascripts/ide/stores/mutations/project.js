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
      projects: { ...state.projects, [projectPath]: project },
    });
  },
  [types.TOGGLE_EMPTY_STATE](state, { projectPath, value }) {
    Object.assign(state.projects[projectPath], {
      empty_repo: value,
    });
  },
  [types.UPDATE_PROJECT](state, { projectPath, props }) {
    const project = state.projects[projectPath];

    if (!project || !props) {
      return;
    }

    Object.keys(props).reduce((acc, key) => {
      project[key] = props[key];
      return project;
    }, project);

    state.projects = {
      ...state.projects,
      [projectPath]: project,
    };
  },
};
