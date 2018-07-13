import { __ } from '../../../locale';
import service from '../../services';
import * as types from '../mutation_types';

export const getMergeRequestData = (
  { commit, dispatch, state },
  { projectId, mergeRequestId, targetProjectId = null, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId] || force) {
      service
        .getProjectMergeRequestData(targetProjectId || projectId, mergeRequestId, {
          render_html: true,
        })
        .then(({ data }) => {
          commit(types.SET_MERGE_REQUEST, {
            projectPath: projectId,
            mergeRequestId,
            mergeRequest: data,
          });
          commit(types.SET_CURRENT_MERGE_REQUEST, mergeRequestId);
          resolve(data);
        })
        .catch(() => {
          dispatch('setErrorMessage', {
            text: __('An error occured whilst loading the merge request.'),
            action: payload =>
              dispatch('getMergeRequestData', payload).then(() =>
                dispatch('setErrorMessage', null),
              ),
            actionText: __('Please try again'),
            actionPayload: { projectId, mergeRequestId, force },
          });
          reject(new Error(`Merge Request not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId]);
    }
  });

export const getMergeRequestChanges = (
  { commit, dispatch, state },
  { projectId, mergeRequestId, targetProjectId = null, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId].changes.length || force) {
      service
        .getProjectMergeRequestChanges(targetProjectId || projectId, mergeRequestId)
        .then(({ data }) => {
          commit(types.SET_MERGE_REQUEST_CHANGES, {
            projectPath: projectId,
            mergeRequestId,
            changes: data,
          });
          resolve(data);
        })
        .catch(() => {
          dispatch('setErrorMessage', {
            text: __('An error occured whilst loading the merge request changes.'),
            action: payload =>
              dispatch('getMergeRequestChanges', payload).then(() =>
                dispatch('setErrorMessage', null),
              ),
            actionText: __('Please try again'),
            actionPayload: { projectId, mergeRequestId, force },
          });
          reject(new Error(`Merge Request Changes not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId].changes);
    }
  });

export const getMergeRequestVersions = (
  { commit, dispatch, state },
  { projectId, mergeRequestId, targetProjectId = null, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId].versions.length || force) {
      service
        .getProjectMergeRequestVersions(targetProjectId || projectId, mergeRequestId)
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
          dispatch('setErrorMessage', {
            text: __('An error occured whilst loading the merge request version data.'),
            action: payload =>
              dispatch('getMergeRequestVersions', payload).then(() =>
                dispatch('setErrorMessage', null),
              ),
            actionText: __('Please try again'),
            actionPayload: { projectId, mergeRequestId, force },
          });
          reject(new Error(`Merge Request Versions not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId].versions);
    }
  });
