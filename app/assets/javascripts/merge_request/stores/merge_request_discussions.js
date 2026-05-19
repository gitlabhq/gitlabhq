import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
import { useNotes } from '~/notes/store/legacy_notes';
import { useDiscussions } from '~/notes/store/discussions';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useMergeRequestDraftNotes } from '~/merge_request/stores/merge_request_draft_notes';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import {
  buildLineDiscussionData,
  buildReplyData,
  buildUpdateNoteData,
  buildDraftLineDiscussionData,
  buildDraftReplyData,
} from '~/merge_request/utils';
import {
  isFileDiscussion,
  isLineDiscussion,
  findApplicablePosition,
  positionMatchesLine,
} from '~/rapid_diffs/utils/discussion_position';
import { reactiveOverride } from '~/lib/utils/reactive_proxy';

export const useMergeRequestDiscussions = defineStore('mergeRequestDiscussions', () => {
  const notes = useNotes();
  const diffDiscussions = useDiffDiscussions();
  const versions = useMergeRequestVersions();
  const draftNotes = useMergeRequestDraftNotes();
  const mrNotes = useMrNotes();
  const allCommentsReady = ref(false);

  const allVisibleDiscussionsExpanded = computed(() => {
    if (mrNotes.isDiffsPage) return diffDiscussions.allDiffDiscussionsExpanded;
    return notes.allDiscussionsExpanded;
  });

  function toggleAllVisibleDiscussions() {
    if (mrNotes.isDiffsPage) {
      diffDiscussions.toggleAllDiffDiscussions();
    } else {
      notes.toggleAllDiscussions();
    }
  }

  function collapseResolvedDiscussions() {
    const discussionsStore = useDiscussions();
    discussionsStore.discussions.forEach((discussion) => {
      if (discussion.resolvable && discussion.resolved && !discussion.hidden) {
        discussionsStore.collapseDiscussion(discussion);
      }
    });
  }

  async function fetchNotes() {
    if (notes.fetchNotesPromise) {
      await notes.fetchNotesPromise;
      collapseResolvedDiscussions();
      return;
    }
    for await (const batch of notes.fetchNotesBatches()) {
      notes.addOrUpdateDiscussions(batch);
      collapseResolvedDiscussions();
    }
  }

  async function fetchNotesAndDrafts() {
    await Promise.all([fetchNotes(), draftNotes.fetchDrafts()]);
    allCommentsReady.value = true;
  }

  async function createNewDiscussion(noteData) {
    await notes.createNewNote({
      endpoint: notes.noteableData.create_note_path,
      data: { note: noteData },
    });
  }

  async function createLineDiscussion(discussion, noteBody) {
    const { diffRefs } = useMergeRequestVersions();
    await notes.saveNote(
      buildLineDiscussionData({
        discussion,
        noteBody,
        noteableData: notes.noteableData,
        viewConfig: useDiffsView(),
        diffRefs,
      }),
    );
    diffDiscussions.removeNewLineDiscussionForm(discussion);
  }

  async function createFileDiscussion(discussion, noteBody) {
    const { diffRefs } = useMergeRequestVersions();
    await notes.saveNote(
      buildLineDiscussionData({
        discussion,
        noteBody,
        noteableData: notes.noteableData,
        viewConfig: useDiffsView(),
        diffRefs,
      }),
    );
    diffDiscussions.removeNewFileDiscussionForm(discussion);
  }

  async function replyToDiscussion(discussion, noteText) {
    const { diffRefs } = useMergeRequestVersions();
    await notes.saveNote(
      buildReplyData({
        discussion,
        noteText,
        noteableData: notes.noteableData,
        diffRefs,
      }),
    );
  }

  async function saveNote(note, noteText) {
    await notes.updateNote(
      buildUpdateNoteData({
        note,
        noteText,
        noteableData: notes.noteableData,
      }),
    );
  }

  async function destroyNote(note) {
    await notes.deleteNote(note);
  }

  async function toggleAwardOnNote(note, name) {
    await notes.toggleAwardRequest({
      endpoint: note.toggle_award_path,
      awardName: name,
      noteId: note.id,
    });
  }

  async function toggleResolveNote(discussion) {
    await notes.toggleResolveNote({
      endpoint: discussion.resolve_path,
      isResolved: discussion.resolved,
      discussion: true,
      discussionId: discussion.id,
    });
  }

  async function createDraftNote(discussion, noteBody) {
    const { draftsPath } = notes.notesData;
    const { diffRefs } = useMergeRequestVersions();
    const data = buildDraftLineDiscussionData({
      discussion,
      noteBody,
      viewConfig: useDiffsView(),
      diffRefs,
    });
    await draftNotes.createNewDraft({ endpoint: draftsPath, data });
  }

  async function createDraftLineDiscussion(discussion, noteBody) {
    await createDraftNote(discussion, noteBody);
    diffDiscussions.removeNewLineDiscussionForm(discussion);
  }

  async function createDraftFileDiscussion(discussion, noteBody) {
    await createDraftNote(discussion, noteBody);
    diffDiscussions.removeNewFileDiscussionForm(discussion);
  }

  async function addDraftToDiscussion(discussion, noteText, resolveDiscussion = false) {
    const { draftsPath } = notes.notesData;
    const { diffRefs } = useMergeRequestVersions();
    const data = buildDraftReplyData({ discussion, noteText, diffRefs, resolveDiscussion });
    await draftNotes.addDraftToDiscussion({ endpoint: draftsPath, data });
  }

  function addNewLineDiscussionForm(params) {
    const { lineChange, lineRange, newPath, extraOptions = {} } = params;
    const { diffRefs, commitId } = versions;
    const newLine = lineRange?.end?.new_line;
    const canSuggest =
      notes.noteableData?.can_receive_suggestion && lineChange?.change !== 'removed';
    const previewParams =
      canSuggest && diffRefs && newPath && newLine
        ? {
            preview_suggestions: true,
            line: newLine,
            file_path: newPath,
            base_sha: diffRefs.base_sha,
            start_sha: diffRefs.start_sha,
            head_sha: diffRefs.head_sha,
          }
        : null;
    return diffDiscussions.addNewLineDiscussionForm({
      ...params,
      positionExtras: diffRefs,
      extraOptions: { ...extraOptions, canSuggest, previewParams, commitId },
    });
  }

  function addNewFileDiscussionForm(params) {
    const { extraOptions = {} } = params;
    const { diffRefs, commitId } = versions;
    return diffDiscussions.addNewFileDiscussionForm({
      ...params,
      positionExtras: diffRefs,
      extraOptions: { ...extraOptions, commitId },
    });
  }

  function withDraftReplies(discussion) {
    const drafts = draftNotes.findDraftsForDiscussion(discussion.id);
    if (!drafts.length) return discussion;
    return reactiveOverride(discussion, { notes: [...discussion.notes, ...drafts] });
  }

  const findDiscussionsForFile = computed(() => {
    const { diffRefs } = versions;
    return ({ oldPath, newPath }) => {
      const all = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter((discussion) => !discussion.isForm && findApplicablePosition(discussion, diffRefs));
      if (!allCommentsReady.value) return all;
      return [
        ...all.map(withDraftReplies),
        ...draftNotes.findDraftsAsDiscussionsForFile({ oldPath, newPath }),
      ];
    };
  });

  const findLinePositionsForFile = computed(() => {
    const { diffRefs } = versions;
    return ({ oldPath, newPath }) => {
      const positions = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter(isLineDiscussion)
        .map((discussion) => findApplicablePosition(discussion, diffRefs))
        .filter(Boolean);
      if (!allCommentsReady.value) return positions;
      return [
        ...positions,
        ...draftNotes
          .findDraftsAsLineDiscussionsForFile({ oldPath, newPath })
          .map((discussion) => discussion.position),
      ];
    };
  });

  const findLineDiscussionsForPosition = computed(() => {
    const { diffRefs } = versions;
    return ({ oldPath, newPath, oldLine, newLine }) => {
      const linePos = { oldPath, newPath, oldLine, newLine };
      const all = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter((discussion) => {
          if (!isLineDiscussion(discussion)) return false;
          const pos = findApplicablePosition(discussion, diffRefs);
          return pos && positionMatchesLine(pos, linePos);
        });
      if (!allCommentsReady.value) return all;
      const enriched = all.map((discussion) =>
        discussion.isForm ? discussion : withDraftReplies(discussion),
      );
      const drafts = draftNotes.findDraftsForPosition({ oldPath, newPath, oldLine, newLine });
      if (!drafts.length) return enriched;
      const discussions = enriched.filter((discussion) => !discussion.isForm);
      const forms = enriched.filter((discussion) => discussion.isForm);
      return [...discussions, ...drafts, ...forms];
    };
  });

  const findAllFileDiscussionsForFile = computed(() => {
    const { diffRefs } = versions;
    return ({ oldPath, newPath }) => {
      const all = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter((d) => isFileDiscussion(d) && findApplicablePosition(d, diffRefs));
      if (!allCommentsReady.value) return all;
      return [
        ...all.map(withDraftReplies),
        ...draftNotes.findDraftsAsFileDiscussionsForFile({ oldPath, newPath }),
      ];
    };
  });

  const findAllImageDiscussionsForFile = computed(() => {
    const { diffRefs } = versions;
    return (oldPath, newPath) => {
      const all = diffDiscussions
        .findAllImageDiscussionsForFile(oldPath, newPath)
        .filter((discussion) => findApplicablePosition(discussion, diffRefs));
      if (!allCommentsReady.value) return all;
      return [
        ...all.map(withDraftReplies),
        ...draftNotes.findDraftsAsImageDiscussionsForFile({ oldPath, newPath }),
      ];
    };
  });

  return {
    allVisibleDiscussionsExpanded,
    toggleAllVisibleDiscussions,
    fetchNotes,
    fetchNotesAndDrafts,
    createNewDiscussion,
    createLineDiscussion,
    createFileDiscussion,
    replyToDiscussion,
    saveNote,
    destroyNote,
    toggleAwardOnNote,
    toggleResolveNote,

    createDraftLineDiscussion,
    createDraftFileDiscussion,
    addDraftToDiscussion,
    updateDraft: draftNotes.updateDraft,
    deleteDraft: draftNotes.deleteDraft,
    findDraftsForDiscussion: (id) =>
      allCommentsReady.value ? draftNotes.findDraftsForDiscussion(id) : [],
    publishReview: draftNotes.publishReview,
    discardDrafts: draftNotes.discardDrafts,
    hasDrafts: computed(() => draftNotes.hasDrafts),
    draftsCount: computed(() => draftNotes.draftsCount),
    isPublishing: computed(() => draftNotes.isPublishing),

    setInitialDiscussions: diffDiscussions.setInitialDiscussions,
    replaceDiscussion: diffDiscussions.replaceDiscussion,
    updateDiscussion: diffDiscussions.updateDiscussion,
    toggleDiscussionReplies: diffDiscussions.toggleDiscussionReplies,
    expandDiscussionReplies: diffDiscussions.expandDiscussionReplies,
    startReplying: diffDiscussions.startReplying,
    stopReplying: diffDiscussions.stopReplying,
    addNote: diffDiscussions.addNote,
    updateNote: diffDiscussions.updateNote,
    updateNoteTextById: diffDiscussions.updateNoteTextById,
    editNote: diffDiscussions.editNote,
    deleteNote: diffDiscussions.deleteNote,
    addDiscussion: diffDiscussions.addDiscussion,
    deleteDiscussion: diffDiscussions.deleteDiscussion,
    setEditingMode: diffDiscussions.setEditingMode,
    requestLastNoteEditing: diffDiscussions.requestLastNoteEditing,
    toggleAward: diffDiscussions.toggleAward,
    collapseDiscussion: diffDiscussions.collapseDiscussion,
    expandDiscussion: diffDiscussions.expandDiscussion,
    addNewLineDiscussionForm,
    replaceDiscussionForm: diffDiscussions.replaceDiscussionForm,
    removeNewLineDiscussionForm: diffDiscussions.removeNewLineDiscussionForm,
    setDiscussionFormText: diffDiscussions.setDiscussionFormText,
    setNewLineDiscussionFormAutofocus: diffDiscussions.setNewLineDiscussionFormAutofocus,
    setFileDiscussionsHidden: diffDiscussions.setFileDiscussionsHidden,
    setPositionDiscussionsHidden: diffDiscussions.setPositionDiscussionsHidden,
    findDiscussionsForFile,
    findLinePositionsForFile,
    findLineDiscussionsForPosition,
    findAllFileDiscussionsForFile,
    findAllImageDiscussionsForFile,
    expandFileDiscussions: diffDiscussions.expandFileDiscussions,
    addNewFileDiscussionForm,
    removeNewFileDiscussionForm: diffDiscussions.removeNewFileDiscussionForm,
    submitSuggestion: notes.submitSuggestion,
    submitSuggestionBatch: notes.submitSuggestionBatch,
    addSuggestionInfoToBatch: notes.addSuggestionInfoToBatch,
    removeSuggestionInfoFromBatch: notes.removeSuggestionInfoFromBatch,
    batchSuggestionsInfo: computed(() => notes.batchSuggestionsInfo),
    suggestionsCount: computed(() => notes.suggestionsCount),
    suggestionsFilePaths: computed(() => notes.getSuggestionsFilePaths()),
  };
});
