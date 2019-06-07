import * as types from '../mutation_types';

export default {
  [types.SET_CURRENT_MERGE_REQUEST](state, currentMergeRequestId) {
    Object.assign(state, {
      currentMergeRequestId,
    });
  },
  [types.SET_MERGE_REQUEST](state, { projectPath, mergeRequestId, mergeRequest }) {
    const existingMergeRequest = state.projects[projectPath].mergeRequests[mergeRequestId] || {};

    Object.assign(state.projects[projectPath], {
      mergeRequests: {
        [mergeRequestId]: {
          ...mergeRequest,
          active: true,
          changes: [],
          versions: [],
          baseCommitSha: null,
          ...existingMergeRequest,
        },
      },
    });
  },
  [types.SET_MERGE_REQUEST_CHANGES](state, { projectPath, mergeRequestId, changes }) {
    Object.assign(state.projects[projectPath].mergeRequests[mergeRequestId], {
      changes,
    });
  },
  [types.SET_MERGE_REQUEST_VERSIONS](state, { projectPath, mergeRequestId, versions }) {
    Object.assign(state.projects[projectPath].mergeRequests[mergeRequestId], {
      versions,
      baseCommitSha: versions.length ? versions[0].base_commit_sha : null,
    });
  },
};
