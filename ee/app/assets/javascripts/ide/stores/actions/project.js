import service from '../../services';
import flash from '../../../flash';
import * as types from '../mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const getProjectData = (
  { commit, state, dispatch },
  { namespace, projectId, force = false } = {},
) => new Promise((resolve, reject) => {
  if (!state.projects[`${namespace}/${projectId}`] || force) {
    commit(types.TOGGLE_LOADING, state);
    service.getProjectData(namespace, projectId)
    .then(res => res.data)
    .then((data) => {
      commit(types.TOGGLE_LOADING, state);
      commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
      if (!state.currentProjectId) commit(types.SET_CURRENT_PROJECT, `${namespace}/${projectId}`);
      resolve(data);
    })
    .catch(() => {
      flash('Error loading project data. Please try again.', 'alert', document, null, false, true);
      reject(new Error(`Project not loaded ${namespace}/${projectId}`));
    });
  } else {
    resolve(state.projects[`${namespace}/${projectId}`]);
  }
});
