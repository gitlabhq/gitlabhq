import flash from '~/flash';
import { __ } from '~/locale';
import service from '../../services';
import * as types from '../mutation_types';
import { activityBarViews } from '../../constants';

export const getMergeRequestsForBranch = ({ commit, state }, { projectId, branchId } = {}) =>
  service
    .getProjectMergeRequests(`${projectId}`, {
      source_branch: branchId,
      source_project_id: state.projects[projectId].id,
      order_by: 'created_at',
      per_page: 1,
    })
    .then(({ data }) => {
      if (data.length > 0) {
        const currentMR = data[0];

        commit(types.SET_MERGE_REQUEST, {
          projectPath: projectId,
          mergeRequestId: currentMR.iid,
          mergeRequest: currentMR,
        });

        commit(types.SET_CURRENT_MERGE_REQUEST, `${currentMR.iid}`);
      }
    })
    .catch(e => {
      flash(
        __(`Error fetching merge requests for ${branchId}`),
        'alert',
        document,
        null,
        false,
        true,
      );
      throw e;
    });

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
            text: __('An error occurred whilst loading the merge request.'),
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
            text: __('An error occurred whilst loading the merge request changes.'),
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
            text: __('An error occurred whilst loading the merge request version data.'),
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

export const openMergeRequest = (
  { dispatch, state },
  { projectId, targetProjectId, mergeRequestId } = {},
) =>
  dispatch('getMergeRequestData', {
    projectId,
    targetProjectId,
    mergeRequestId,
  })
    .then(mr => {
      dispatch('setCurrentBranchId', mr.source_branch);

      // getFiles needs to be called after getting the branch data
      // since files are fetched using the last commit sha of the branch
      return dispatch('getBranchData', {
        projectId,
        branchId: mr.source_branch,
      }).then(() =>
        dispatch('getFiles', {
          projectId,
          branchId: mr.source_branch,
        }),
      );
    })
    .then(() =>
      dispatch('getMergeRequestVersions', {
        projectId,
        targetProjectId,
        mergeRequestId,
      }),
    )
    .then(() =>
      dispatch('getMergeRequestChanges', {
        projectId,
        targetProjectId,
        mergeRequestId,
      }),
    )
    .then(mrChanges => {
      if (mrChanges.changes.length) {
        dispatch('updateActivityBarView', activityBarViews.review);
      }

      mrChanges.changes.forEach((change, ind) => {
        const changeTreeEntry = state.entries[change.new_path];

        if (changeTreeEntry) {
          dispatch('setFileMrChange', {
            file: changeTreeEntry,
            mrChange: change,
          });

          if (ind < 10) {
            dispatch('getFileData', {
              path: change.new_path,
              makeFileActive: ind === 0,
              openFile: true,
            });
          }
        }
      });
    })
    .catch(e => {
      flash(__('Error while loading the merge request. Please try again.'));
      throw e;
    });
