import flash from '~/flash';
import service from '../../services';
import * as types from '../mutation_types';

export const getMergeRequestData = (
  { commit, state, dispatch },
  { projectId, mergeRequestId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId] || force) {
      service
        .getProjectMergeRequestData(projectId, mergeRequestId)
        .then(res => res.data)
        .then(data => {
          commit(types.SET_MERGE_REQUEST, {
            projectPath: projectId,
            mergeRequestId,
            mergeRequest: data,
          });
          if (!state.currentMergeRequestId) {
            commit(types.SET_CURRENT_MERGE_REQUEST, mergeRequestId);
          }
          resolve(data);
        })
        .catch(() => {
          flash('Error loading merge request data. Please try again.');
          reject(new Error(`Merge Request not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId]);
    }
  });

export const getMergeRequestChanges = (
  { commit, state, dispatch },
  { projectId, mergeRequestId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId].changes.length || force) {
      service
        .getProjectMergeRequestChanges(projectId, mergeRequestId)
        .then(res => res.data)
        .then(data => {
          commit(types.SET_MERGE_REQUEST_CHANGES, {
            projectPath: projectId,
            mergeRequestId,
            changes: data,
          });
          resolve(data);
        })
        .catch(() => {
          flash('Error loading merge request changes. Please try again.');
          reject(new Error(`Merge Request Changes not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId].changes);
    }
  });

export const getMergeRequestVersions = (
  { commit, state, dispatch },
  { projectId, mergeRequestId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId].versions.length || force) {
      service
        .getProjectMergeRequestVersions(projectId, mergeRequestId)
        .then(res => res.data)
        .then(data => {
          commit(types.SET_MERGE_REQUEST_VERSIONS, {
            projectPath: projectId,
            mergeRequestId,
            versions: data,
          });
          resolve(data);
        })
        .catch(() => {
          flash('Error loading merge request versions. Please try again.');
          reject(new Error(`Merge Request Versions not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId].versions);
    }
  });
