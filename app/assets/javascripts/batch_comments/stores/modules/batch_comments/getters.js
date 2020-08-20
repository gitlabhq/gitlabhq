import { parallelLineKey, showDraftOnSide } from '../../../utils';

export const draftsCount = state => state.drafts.length;

export const getNotesData = (state, getters, rootState, rootGetters) => rootGetters.getNotesData;

export const hasDrafts = state => state.drafts.length > 0;

export const draftsPerDiscussionId = state =>
  state.drafts.reduce((acc, draft) => {
    if (draft.discussion_id) {
      acc[draft.discussion_id] = draft;
    }

    return acc;
  }, {});

export const draftsPerFileHashAndLine = state =>
  state.drafts.reduce((acc, draft) => {
    if (draft.file_hash) {
      if (!acc[draft.file_hash]) {
        acc[draft.file_hash] = {};
      }

      acc[draft.file_hash][draft.line_code] = draft;
    }

    return acc;
  }, {});

export const shouldRenderDraftRow = (state, getters) => (diffFileSha, line) =>
  Boolean(
    diffFileSha in getters.draftsPerFileHashAndLine &&
      getters.draftsPerFileHashAndLine[diffFileSha][line.line_code],
  );

export const shouldRenderParallelDraftRow = (state, getters) => (diffFileSha, line) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
  const [lkey, rkey] = [parallelLineKey(line, 'left'), parallelLineKey(line, 'right')];

  return draftsForFile ? Boolean(draftsForFile[lkey] || draftsForFile[rkey]) : false;
};

export const hasParallelDraftLeft = (state, getters) => (diffFileSha, line) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
  const lkey = parallelLineKey(line, 'left');

  return draftsForFile ? Boolean(draftsForFile[lkey]) : false;
};

export const hasParallelDraftRight = (state, getters) => (diffFileSha, line) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];
  const rkey = parallelLineKey(line, 'left');

  return draftsForFile ? Boolean(draftsForFile[rkey]) : false;
};

export const shouldRenderDraftRowInDiscussion = (state, getters) => discussionId =>
  typeof getters.draftsPerDiscussionId[discussionId] !== 'undefined';

export const draftForDiscussion = (state, getters) => discussionId =>
  getters.draftsPerDiscussionId[discussionId] || {};

export const draftForLine = (state, getters) => (diffFileSha, line, side = null) => {
  const draftsForFile = getters.draftsPerFileHashAndLine[diffFileSha];

  const key = side !== null ? parallelLineKey(line, side) : line.line_code;

  if (draftsForFile) {
    const draft = draftsForFile[key];
    if (draft && showDraftOnSide(line, side)) {
      return draft;
    }
  }
  return {};
};

export const draftsForFile = state => diffFileSha =>
  state.drafts.filter(draft => draft.file_hash === diffFileSha);

export const isPublishingDraft = state => draftId =>
  state.currentlyPublishingDrafts.indexOf(draftId) !== -1;

export const sortedDrafts = state => [...state.drafts].sort((a, b) => a.id > b.id);
