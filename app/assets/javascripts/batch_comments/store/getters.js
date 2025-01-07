import { parallelLineKey, showDraftOnSide } from '../utils';

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
  return (diffFileSha, line) =>
    Boolean(
      diffFileSha in this.draftsPerFileHashAndLine &&
        this.draftsPerFileHashAndLine[diffFileSha][line.line_code],
    );
}

export function shouldRenderParallelDraftRow() {
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const [lkey, rkey] = [parallelLineKey(line, 'left'), parallelLineKey(line, 'right')];

    return drafts ? Boolean(drafts[lkey] || drafts[rkey]) : false;
  };
}

export function hasParallelDraftLeft() {
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const lkey = parallelLineKey(line, 'left');

    return drafts ? Boolean(drafts[lkey]) : false;
  };
}

export function hasParallelDraftRight() {
  return (diffFileSha, line) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const rkey = parallelLineKey(line, 'left');

    return drafts ? Boolean(drafts[rkey]) : false;
  };
}

export function shouldRenderDraftRowInDiscussion() {
  return (discussionId) => typeof this.draftsPerDiscussionId[discussionId] !== 'undefined';
}

export function draftForDiscussion() {
  return (discussionId) => this.draftsPerDiscussionId[discussionId] || {};
}

export function draftsForLine() {
  return (diffFileSha, line, side = null) => {
    const drafts = this.draftsPerFileHashAndLine[diffFileSha];
    const key = side !== null ? parallelLineKey(line, side) : line.line_code;
    const showDraftsForThisSide = showDraftOnSide(line, side);

    if (showDraftsForThisSide && drafts?.[key]) {
      return drafts[key].filter((d) => d.position.position_type === 'text');
    }
    return [];
  };
}

export function draftsForFile() {
  return (diffFileSha) => this.drafts.filter((draft) => draft.file_hash === diffFileSha);
}

export function isPublishingDraft() {
  return (draftId) => this.currentlyPublishingDrafts.indexOf(draftId) !== -1;
}

export function sortedDrafts() {
  return [...this.drafts].sort((a, b) => a.id > b.id);
}
