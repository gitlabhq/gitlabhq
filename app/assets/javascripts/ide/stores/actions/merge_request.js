import { createAlert } from '~/alert';
import { STATUS_OPEN } from '~/issues/constants';
import { sprintf, __ } from '~/locale';
import { leftSidebarViews, PERMISSION_READ_MR, MAX_MR_FILES_AUTO_OPEN } from '../../constants';
import service from '../../services';
import * as types from '../mutation_types';

export const getMergeRequestsForBranch = (
  { commit, state, getters },
  { projectId, branchId } = {},
) => {
  if (!getters.findProjectPermissions(projectId)[PERMISSION_READ_MR]) {
    return Promise.resolve();
  }

  return service
    .getProjectMergeRequests(`${projectId}`, {
      source_branch: branchId,
      source_project_id: state.projects[projectId].id,
      state: STATUS_OPEN,
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
    .catch((e) => {
      createAlert({
        message: sprintf(__('Error fetching merge requests for %{branchId}'), { branchId }),
        fadeTransition: false,
        addBodyClass: true,
      });
      throw e;
    });
};

export const getMergeRequestData = (
  { commit, dispatch, state },
  { projectId, mergeRequestId, targetProjectId = null, force = false } = {},
) =>
  new Promise((resolve, reject) => {
    if (!state.projects[projectId].mergeRequests[mergeRequestId] || force) {
      service
        .getProjectMergeRequestData(targetProjectId || projectId, mergeRequestId)
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
            text: __('An error occurred while loading the merge request.'),
            action: (payload) =>
              dispatch('getMergeRequestData', payload).then(() =>
                dispatch('setErrorMessage', null),
              ),
            actionText: __('Please try again'),
            actionPayload: { projectId, mergeRequestId, force },
          });
          reject(new Error(`Merge request not loaded ${projectId}`));
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
            text: __('An error occurred while loading the merge request changes.'),
            action: (payload) =>
              dispatch('getMergeRequestChanges', payload).then(() =>
                dispatch('setErrorMessage', null),
              ),
            actionText: __('Please try again'),
            actionPayload: { projectId, mergeRequestId, force },
          });
          reject(new Error(`Merge request changes not loaded ${projectId}`));
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
        .then((res) => res.data)
        .then((data) => {
          commit(types.SET_MERGE_REQUEST_VERSIONS, {
            projectPath: projectId,
            mergeRequestId,
            versions: data,
          });
          resolve(data);
        })
        .catch(() => {
          dispatch('setErrorMessage', {
            text: __('An error occurred while loading the merge request version data.'),
            action: (payload) =>
              dispatch('getMergeRequestVersions', payload).then(() =>
                dispatch('setErrorMessage', null),
              ),
            actionText: __('Please try again'),
            actionPayload: { projectId, mergeRequestId, force },
          });
          reject(new Error(`Merge request versions not loaded ${projectId}`));
        });
    } else {
      resolve(state.projects[projectId].mergeRequests[mergeRequestId].versions);
    }
  });

export const openMergeRequestChanges = async ({ dispatch, getters, state, commit }, changes) => {
  const entryChanges = changes
    .map((change) => ({ entry: state.entries[change.new_path], change }))
    .filter((x) => x.entry);

  const pathsToOpen = entryChanges
    .slice(0, MAX_MR_FILES_AUTO_OPEN)
    .map(({ change }) => change.new_path);

  // If there are no changes with entries, do nothing.
  if (!entryChanges.length) {
    return;
  }

  dispatch('updateActivityBarView', leftSidebarViews.review.name);

  entryChanges.forEach(({ change, entry }) => {
    commit(types.SET_FILE_MERGE_REQUEST_CHANGE, { file: entry, mrChange: change });
  });

  // Open paths in order as they appear in MR changes
  pathsToOpen.forEach((path) => {
    commit(types.TOGGLE_FILE_OPEN, path);
  });

  // Activate first path.
  // We don't `getFileData` here since the editor component kicks that off. Otherwise, we'd fetch twice.
  const [firstPath, ...remainingPaths] = pathsToOpen;
  await dispatch('router/push', getters.getUrlForPath(firstPath));
  await dispatch('setFileActive', firstPath);

  // Lastly, eagerly fetch the remaining paths for improved user experience.
  await Promise.all(
    remainingPaths.map(async (path) => {
      try {
        await dispatch('getFileData', {
          path,
          makeFileActive: false,
        });
        await dispatch('getRawFileData', { path });
      } catch (e) {
        // If one of the file fetches fails, we dont want to blow up the rest of them.
        // eslint-disable-next-line no-console
        console.error('[gitlab] An unexpected error occurred fetching MR file data', e);
      }
    }),
  );
};

export const openMergeRequest = async (
  { dispatch, getters },
  { projectId, targetProjectId, mergeRequestId } = {},
) => {
  try {
    const mr = await dispatch('getMergeRequestData', {
      projectId,
      targetProjectId,
      mergeRequestId,
    });

    dispatch('setCurrentBranchId', mr.source_branch);

    await dispatch('getBranchData', {
      projectId,
      branchId: mr.source_branch,
    });

    const branch = getters.findBranch(projectId, mr.source_branch);

    await dispatch('getFiles', {
      projectId,
      branchId: mr.source_branch,
      ref: branch.commit.id,
    });

    await dispatch('getMergeRequestVersions', {
      projectId,
      targetProjectId,
      mergeRequestId,
    });

    const { changes } = await dispatch('getMergeRequestChanges', {
      projectId,
      targetProjectId,
      mergeRequestId,
    });

    await dispatch('openMergeRequestChanges', changes);
  } catch (e) {
    createAlert({ message: __('Error while loading the merge request. Please try again.') });
    throw e;
  }
};
