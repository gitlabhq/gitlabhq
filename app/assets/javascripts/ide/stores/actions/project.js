import service from '../../services';
import flash from '../../../flash';
import * as types from '../mutation_types';

export const getProjectData = (
  { commit, state, dispatch },
  { namespace, projectId, force = false } = {},
) => new Promise((resolve, reject) => {
  if (!state.projects[`${namespace}/${projectId}`] || force) {
    service.getProjectData(namespace, projectId)
    .then(res => res.data)
    .then((data) => {
      commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
      resolve(data);
    })
    .catch(() => {
      flash('Error loading project data. Please try again.');
      reject(new Error('Project not loaded'));
    });
  } else {
    resolve(state.projects[`${namespace}/${projectId}`]);
  }
});
