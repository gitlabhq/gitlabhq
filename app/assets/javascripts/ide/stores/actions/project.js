import service from '../../services';
import flash from '../../../flash';
import * as types from '../mutation_types';

export const getProjectData = (
  { commit, state, dispatch },
  { namespace, projectId } = {},
) => service.getProjectData(namespace, projectId)
    .then(res => res.data)
    .then((data) => {
      commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
    })
    .catch(() => {
      flash('Error loading project data. Please try again.');
      throw new Error('Project not loaded');
    });
