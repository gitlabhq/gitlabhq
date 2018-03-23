import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_MERGE_REQUEST](state, currentMergeRequestId) {
    Object.assign(state, {
      currentMergeRequestId,
    });
  },
  [types.SET_MERGE_REQUEST](
    state,
    { projectPath, mergeRequestId, mergeRequest },
  ) {
    // Add client side properties
    Object.assign(mergeRequest, {
      active: true,
    });

    Object.assign(state.projects[projectPath], {
      mergeRequests: {
        [mergeRequestId]: mergeRequest,
      },
    });
  },
  [types.SET_MERGE_REQUEST_CHANGES](
    state,
    { projectPath, mergeRequestId, changes },
  ) {
    Object.assign(state.projects[projectPath].mergeRequests[mergeRequestId], {
      changes,
    });
  },
  [types.SET_MERGE_REQUEST_NOTES](
    state,
    { projectPath, mergeRequestId, notes },
  ) {
    Object.assign(state.projects[projectPath].mergeRequests[mergeRequestId], {
      notes,
    });
  },
};
