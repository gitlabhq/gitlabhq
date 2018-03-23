import flash from '~/flash';
import service from '../../services';
import * as types from '../mutation_types';

// eslint-disable-next-line import/prefer-default-export
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
            commit(
              types.SET_CURRENT_MERGE_REQUEST,
              `${projectId}/${mergeRequestId}`,
            );
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

// eslint-disable-next-line import/prefer-default-export
export const getMergeRequestChanges = (
  { commit, state, dispatch },
  { projectId, mergeRequestId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (
      !state.projects[projectId].mergeRequests[mergeRequestId].changes ||
      force
    ) {
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

// eslint-disable-next-line import/prefer-default-export
export const getMergeRequestNotes = (
  { commit, state, dispatch },
  { projectId, mergeRequestId, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (
      !state.projects[projectId].mergeRequests[mergeRequestId].notes ||
      force
    ) {
      service
        .getProjectMergeRequestNotes(projectId, mergeRequestId)
        .then(res => res.data)
        .then(data => {
          commit(types.SET_MERGE_REQUEST_NOTES, {
            projectPath: projectId,
            mergeRequestId,
            notes: data,
          });
          resolve(data);
        })
        .catch(() => {
          flash('Error loading merge request notes. Please try again.');
          reject(new Error(`Merge Request Notes not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId].notes);
    }
  });
