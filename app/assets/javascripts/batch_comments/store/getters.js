import { parallelLineKey, showDraftOnSide } from '../utils';

function matchesDiffContext(diffsStore, diffFileSha, draft) {
  if (!diffsStore) return true;

  const { commitId } = diffsStore;
  if (commitId) {
    return draft.position?.head_sha === commitId;
  }

  if (diffsStore.latestDiff) return true;

  const diffFile = diffsStore.getDiffFileByHash(diffFileSha);
  const currentHeadSha = diffFile?.diff_refs?.head_sha;
  if (!currentHeadSha) return true;
  return draft.position?.head_sha === currentHeadSha;
}

export function draftsCount() {
  return this.drafts.length;
}

export function getNotesData() {
  return this.tryStore('legacyNotes').getNotesData;
}

export function hasDrafts() {
  return this.drafts.length > 0;
}

export function draftsPerDiscussionId() {
  return this.drafts.reduce((acc, draft) => {
    if (draft.discussion_id) {
      acc[draft.discussion_id] = draft;
    }

    return acc;
  }, {});
}

export function draftsPerFileHashAndLine() {
  return this.drafts.reduce((acc, draft) => {
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
}

export function shouldRenderDraftRow() {
  const diffsStore = this.tryStore('legacyDiffs');
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha]?.[line.line_code];
    return Boolean(drafts?.some((d) => matchesDiffContext(diffsStore, diffFileSha, d)));
  };
}

export function shouldRenderParallelDraftRow() {
  const diffsStore = this.tryStore('legacyDiffs');
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    if (!drafts) return false;
    const [lkey, rkey] = [parallelLineKey(line, 'left'), parallelLineKey(line, 'right')];
    const hasLeft = drafts[lkey]?.some((d) => matchesDiffContext(diffsStore, diffFileSha, d));
    const hasRight = drafts[rkey]?.some((d) => matchesDiffContext(diffsStore, diffFileSha, d));
    return Boolean(hasLeft || hasRight);
  };
}

export function hasParallelDraftLeft() {
  const diffsStore = this.tryStore('legacyDiffs');
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const lkey = parallelLineKey(line, 'left');
    return Boolean(drafts?.[lkey]?.some((d) => matchesDiffContext(diffsStore, diffFileSha, d)));
  };
}

export function hasParallelDraftRight() {
  const diffsStore = this.tryStore('legacyDiffs');
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const rkey = parallelLineKey(line, 'left');
    return Boolean(drafts?.[rkey]?.some((d) => matchesDiffContext(diffsStore, diffFileSha, d)));
  };
}

export function shouldRenderDraftRowInDiscussion() {
  return (discussionId) => typeof this.draftsPerDiscussionId[discussionId] !== 'undefined';
}

export function draftForDiscussion() {
  return (discussionId) => this.draftsPerDiscussionId[discussionId] || {};
}

export function draftsForLine() {
  const diffsStore = this.tryStore('legacyDiffs');
  return (diffFileSha, line, side = null) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const key = side !== null ? parallelLineKey(line, side) : line.line_code;
    const showDraftsForThisSide = showDraftOnSide(line, side);

    if (showDraftsForThisSide && drafts?.[key]) {
      return drafts[key].filter(
        (d) =>
          d.position.position_type === 'text' && matchesDiffContext(diffsStore, diffFileSha, d),
      );
    }
    return [];
  };
}

export function draftsForFile() {
  return (diffFileSha) => this.drafts.filter((draft) => draft.file_hash === diffFileSha);
}

export function sortedDrafts() {
  return [...this.drafts].sort((a, b) => a.id > b.id);
}
