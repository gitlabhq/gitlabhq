import { parallelLineKey, showDraftOnSide } from '../../../utils';

function matchesDiffContext(rootState, diffFileSha, draft) {
  const { diffs } = rootState;
  if (!diffs) return true;

  const commitId = diffs.commit?.id;
  if (commitId) {
    return draft.position?.head_sha === commitId;
  }

  if (diffs.latestDiff) return true;

  const diffFile = diffs.diffFiles?.find((f) => f.file_hash === diffFileSha);
  const currentHeadSha = diffFile?.diff_refs?.head_sha;
  if (!currentHeadSha) return true;
  return draft.position?.head_sha === currentHeadSha;
}

export const draftsCount = (state) => state.drafts.length;

// eslint-disable-next-line max-params
export const getNotesData = (state, getters, rootState, rootGetters) => rootGetters.getNotesData;

export const hasDrafts = (state) => state.drafts.length > 0;

export const draftsPerDiscussionId = (state) =>
  state.drafts.reduce((acc, draft) => {
    if (draft.discussion_id) {
      acc[draft.discussion_id] = draft;
    }

    return acc;
  }, {});

export const draftsPerFileHashAndLine = (state) =>
  state.drafts.reduce((acc, draft) => {
    if (draft.file_hash) {
      if (!acc[draft.file_hash]) {
        acc[draft.file_hash] = {};
      }

      if (!acc[draft.file_hash][draft.line_code]) {
        acc[draft.file_hash][draft.line_code] = [];
      }

      acc[draft.file_hash][draft.line_code].push(draft);
    }

    return acc;
  }, {});

export const shouldRenderDraftRow = (state, getters, rootState) => (diffFileSha, line) => {
  const drafts = getters.draftsPerFileHashAndLine[diffFileSha]?.[line.line_code];
  return Boolean(drafts?.some((d) => matchesDiffContext(rootState, diffFileSha, d)));
};

export const shouldRenderParallelDraftRow = (state, getters, rootState) => (diffFileSha, line) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
  if (!draftsForFile) return false;
  const [lkey, rkey] = [parallelLineKey(line, 'left'), parallelLineKey(line, 'right')];
  const hasLeft = draftsForFile[lkey]?.some((d) => matchesDiffContext(rootState, diffFileSha, d));
  const hasRight = draftsForFile[rkey]?.some((d) => matchesDiffContext(rootState, diffFileSha, d));
  return Boolean(hasLeft || hasRight);
};

export const hasParallelDraftLeft = (state, getters, rootState) => (diffFileSha, line) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
  const lkey = parallelLineKey(line, 'left');
  return Boolean(draftsForFile?.[lkey]?.some((d) => matchesDiffContext(rootState, diffFileSha, d)));
};

export const hasParallelDraftRight = (state, getters, rootState) => (diffFileSha, line) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
  const rkey = parallelLineKey(line, 'left');
  return Boolean(draftsForFile?.[rkey]?.some((d) => matchesDiffContext(rootState, diffFileSha, d)));
};

export const shouldRenderDraftRowInDiscussion = (state, getters) => (discussionId) =>
  typeof getters.draftsPerDiscussionId[discussionId] !== 'undefined';

export const draftForDiscussion = (state, getters) => (discussionId) =>
  getters.draftsPerDiscussionId[discussionId] || {};

export const draftsForLine =
  (state, getters, rootState) =>
  (diffFileSha, line, side = null) => {
    const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
    const key = side !== null ? parallelLineKey(line, side) : line.line_code;
    const showDraftsForThisSide = showDraftOnSide(line, side);

    if (showDraftsForThisSide && draftsForFile?.[key]) {
      return draftsForFile[key].filter(
        (d) => d.position.position_type === 'text' && matchesDiffContext(rootState, diffFileSha, d),
      );
    }
    return [];
  };

export const draftsForFile = (state) => (diffFileSha) =>
  state.drafts.filter((draft) => draft.file_hash === diffFileSha);

export const sortedDrafts = (state) => [...state.drafts].sort((a, b) => a.id > b.id);
