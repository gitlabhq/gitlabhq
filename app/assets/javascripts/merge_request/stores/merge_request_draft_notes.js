import { computed } from 'vue';
import { defineStore } from 'pinia';
import { useBatchComments } from '~/batch_comments/store';
import {
  findApplicablePosition,
  isFileDiscussion,
  isImageDiscussion,
  isLineDiscussion,
  positionMatchesFilePath,
  positionMatchesLine,
} from '~/rapid_diffs/utils/discussion_position';

function draftAsDiscussion(draft, position = draft.position) {
  return {
    id: `draft_${draft.id}`,
    isDraft: true,
    draft,
    diff_discussion: true,
    position,
    notes: [draft],
    resolvable: false,
    resolved: false,
    individual_note: false,
    isReplying: false,
    repliesExpanded: true,
  };
}

function applicableDraftPosition(draft, diffRefs, isLatestVersion) {
  if (diffRefs) {
    const matched = findApplicablePosition(draft, diffRefs);
    if (matched) return matched;
    if (!isLatestVersion) return undefined;
  }
  return draft.original_position ?? draft.position;
}

export const useMergeRequestDraftNotes = defineStore('mergeRequestDraftNotes', () => {
  const batchComments = useBatchComments();

  const drafts = computed(() => batchComments.drafts);
  const hasDrafts = computed(() => drafts.value.length > 0);
  const draftsCount = computed(() => drafts.value.length);
  const isPublishing = computed(() => batchComments.isPublishing);

  const newDrafts = computed(() =>
    drafts.value.filter((draft) => draft.position && !draft.discussion_id),
  );

  function findDraftsForDiscussion(discussionId) {
    return drafts.value.filter((draft) => draft.discussion_id === discussionId);
  }

  function findDraftsForPosition({
    oldPath,
    newPath,
    oldLine,
    newLine,
    diffRefs,
    isLatestVersion,
  }) {
    return newDrafts.value
      .filter((draft) => {
        const position = applicableDraftPosition(draft, diffRefs, isLatestVersion);
        return position && positionMatchesLine(position, { oldPath, newPath, oldLine, newLine });
      })
      .map((draft) =>
        draftAsDiscussion(draft, applicableDraftPosition(draft, diffRefs, isLatestVersion)),
      );
  }

  function findDraftsAsDiscussionsForFile({ oldPath, newPath, diffRefs, isLatestVersion }) {
    return newDrafts.value
      .filter(
        (draft) =>
          positionMatchesFilePath(draft.position, { oldPath, newPath }) &&
          applicableDraftPosition(draft, diffRefs, isLatestVersion),
      )
      .map((draft) =>
        draftAsDiscussion(draft, applicableDraftPosition(draft, diffRefs, isLatestVersion)),
      );
  }

  function findDraftsAsLineDiscussionsForFile({ oldPath, newPath, diffRefs, isLatestVersion }) {
    return newDrafts.value
      .filter(
        (draft) =>
          isLineDiscussion(draft) &&
          positionMatchesFilePath(draft.position, { oldPath, newPath }) &&
          applicableDraftPosition(draft, diffRefs, isLatestVersion),
      )
      .map((draft) =>
        draftAsDiscussion(draft, applicableDraftPosition(draft, diffRefs, isLatestVersion)),
      );
  }

  function findDraftsAsFileDiscussionsForFile({ oldPath, newPath, diffRefs, isLatestVersion }) {
    return newDrafts.value
      .filter(
        (draft) =>
          isFileDiscussion(draft) &&
          positionMatchesFilePath(draft.position, { oldPath, newPath }) &&
          applicableDraftPosition(draft, diffRefs, isLatestVersion),
      )
      .map((draft) =>
        draftAsDiscussion(draft, applicableDraftPosition(draft, diffRefs, isLatestVersion)),
      );
  }

  function findDraftsAsImageDiscussionsForFile({ oldPath, newPath, diffRefs, isLatestVersion }) {
    return newDrafts.value
      .filter(
        (draft) =>
          isImageDiscussion(draft) &&
          positionMatchesFilePath(draft.position, { oldPath, newPath }) &&
          applicableDraftPosition(draft, diffRefs, isLatestVersion),
      )
      .map((draft) =>
        draftAsDiscussion(draft, applicableDraftPosition(draft, diffRefs, isLatestVersion)),
      );
  }

  async function fetchDrafts() {
    if (!window.gon?.current_user_id) return;
    await batchComments.fetchDrafts();
  }

  return {
    drafts,
    hasDrafts,
    draftsCount,
    isPublishing,

    findDraftsForDiscussion,
    findDraftsForPosition,
    findDraftsAsDiscussionsForFile,
    findDraftsAsLineDiscussionsForFile,
    findDraftsAsFileDiscussionsForFile,
    findDraftsAsImageDiscussionsForFile,

    fetchDrafts,
    createNewDraft: batchComments.createNewDraft,
    addDraftToDiscussion: batchComments.addDraftToDiscussion,
    updateDraft: batchComments.updateDraft,
    deleteDraft: batchComments.deleteDraft,
    publishReview: batchComments.publishReview,
    discardDrafts: batchComments.discardDrafts,
  };
});
