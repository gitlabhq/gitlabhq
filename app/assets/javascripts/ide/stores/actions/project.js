import flash from '~/flash';
import service from '../../services';
import * as types from '../mutation_types';

export const getProjectData = (
  { commit, state, dispatch },
  { namespace, projectId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[`${namespace}/${projectId}`] || force) {
      commit(types.TOGGLE_LOADING, { entry: state });
      service
        .getProjectData(namespace, projectId)
        .then(res => res.data)
        .then(data => {
          commit(types.TOGGLE_LOADING, { entry: state });
          commit(types.SET_PROJECT, { projectPath: `${namespace}/${projectId}`, project: data });
          if (!state.currentProjectId)
            commit(types.SET_CURRENT_PROJECT, `${namespace}/${projectId}`);
          resolve(data);
        })
        .catch(() => {
          flash(
            'Error loading project data. Please try again.',
            'alert',
            document,
            null,
            false,
            true,
          );
          reject(new Error(`Project not loaded ${namespace}/${projectId}`));
        });
    } else {
      resolve(state.projects[`${namespace}/${projectId}`]);
    }
  });

export const getBranchData = (
  { commit, state, dispatch },
  { projectId, branchId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (
      typeof state.projects[`${projectId}`] === 'undefined' ||
      !state.projects[`${projectId}`].branches[branchId] ||
      force
    ) {
      service
        .getBranchData(`${projectId}`, branchId)
        .then(({ data }) => {
          const { id } = data.commit;
          commit(types.SET_BRANCH, {
            projectPath: `${projectId}`,
            branchName: branchId,
            branch: data,
          });
          commit(types.SET_BRANCH_WORKING_REFERENCE, { projectId, branchId, reference: id });
          resolve(data);
        })
        .catch(() => {
          flash(
            'Error loading branch data. Please try again.',
            'alert',
            document,
            null,
            false,
            true,
          );
          reject(new Error(`Branch not loaded - ${projectId}/${branchId}`));
        });
    } else {
      resolve(state.projects[`${projectId}`].branches[branchId]);
    }
  });
