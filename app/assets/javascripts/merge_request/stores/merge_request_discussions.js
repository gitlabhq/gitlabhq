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
  const lineRangeEditing = ref(null);

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

  async function createLineDiscussion({ discussion, noteBody, showWhitespace }) {
    const { sourceHeadSha } = useMergeRequestVersions();
    await notes.saveNote(
      buildLineDiscussionData({
        discussion,
        noteBody,
        noteableData: notes.noteableData,
        viewConfig: useDiffsView(),
        sourceHeadSha,
        showWhitespace,
      }),
    );
    diffDiscussions.removeNewLineDiscussionForm(discussion);
  }

  async function createFileDiscussion({ discussion, noteBody, showWhitespace }) {
    const { sourceHeadSha } = useMergeRequestVersions();
    await notes.saveNote(
      buildLineDiscussionData({
        discussion,
        noteBody,
        noteableData: notes.noteableData,
        viewConfig: useDiffsView(),
        sourceHeadSha,
        showWhitespace,
      }),
    );
    diffDiscussions.removeNewFileDiscussionForm(discussion);
  }

  async function createImageDiscussion({ position, noteBody }) {
    const { sourceHeadSha } = useMergeRequestVersions();
    await notes.saveNote(
      buildLineDiscussionData({
        discussion: { position },
        noteBody,
        noteableData: notes.noteableData,
        viewConfig: useDiffsView(),
        sourceHeadSha,
      }),
    );
  }

  async function replyToDiscussion(discussion, noteText) {
    const { sourceHeadSha } = useMergeRequestVersions();
    await notes.saveNote(
      buildReplyData({
        discussion,
        noteText,
        noteableData: notes.noteableData,
        sourceHeadSha,
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

  async function createDraftNote({ discussion, noteBody, showWhitespace }) {
    const { draftsPath } = notes.notesData;
    const data = buildDraftLineDiscussionData({
      discussion,
      noteBody,
      viewConfig: useDiffsView(),
      showWhitespace,
    });
    await draftNotes.createNewDraft({ endpoint: draftsPath, data });
  }

  async function createDraftLineDiscussion({ discussion, noteBody, showWhitespace }) {
    await createDraftNote({ discussion, noteBody, showWhitespace });
    diffDiscussions.removeNewLineDiscussionForm(discussion);
  }

  async function createDraftFileDiscussion({ discussion, noteBody, showWhitespace }) {
    await createDraftNote({ discussion, noteBody, showWhitespace });
    diffDiscussions.removeNewFileDiscussionForm(discussion);
  }

  async function addDraftToDiscussion(discussion, noteText, resolveDiscussion = false) {
    const { draftsPath } = notes.notesData;
    const { sourceHeadSha } = useMergeRequestVersions();
    const data = buildDraftReplyData({ discussion, noteText, sourceHeadSha, resolveDiscussion });
    await draftNotes.addDraftToDiscussion({ endpoint: draftsPath, data });
  }

  function addNewLineDiscussionForm(params) {
    const { lineChange, lineRange, newPath, extraOptions = {} } = params;
    const { commitId } = versions;
    const diffRefs = params.diffRefs ?? versions.diffRefs;
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
      extraOptions: {
        ...extraOptions,
        canSuggest,
        previewParams,
        commitId,
        editingLineRange: false,
      },
    });
  }

  function startLineRangeEditing(discussion) {
    const editing = { discussion, lineRange: discussion.position.line_range };
    editing.discussion.editingLineRange = true;
    lineRangeEditing.value = editing;
  }

  function cancelLineRangeEditing() {
    const editing = lineRangeEditing.value;
    if (editing) {
      editing.discussion.editingLineRange = false;
      diffDiscussions.setNewLineDiscussionFormAutofocus(editing.discussion, true);
    }
    lineRangeEditing.value = null;
  }

  function commitLineRangeEditing({ lineChange, lineCode, lines }) {
    const editing = lineRangeEditing.value;
    if (!editing) return;
    const { discussion, lineRange } = editing;
    const {
      old_path: oldPath,
      new_path: newPath,
      base_sha: baseSha,
      head_sha: headSha,
      start_sha: startSha,
    } = discussion.position;
    cancelLineRangeEditing();
    diffDiscussions.removeNewLineDiscussionForm(discussion);
    addNewLineDiscussionForm({
      oldPath,
      newPath,
      lineRange,
      lineChange,
      lineCode,
      diffRefs:
        baseSha || headSha || startSha
          ? { base_sha: baseSha, head_sha: headSha, start_sha: startSha }
          : undefined,
      extraOptions: { lines },
      noteBody: discussion.noteBody,
    });
  }

  function addNewFileDiscussionForm(params) {
    const { extraOptions = {} } = params;
    const { commitId } = versions;
    const diffRefs = params.diffRefs ?? versions.diffRefs;
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
    const { isLatestVersion } = versions;
    return ({ oldPath, newPath, diffRefs }) => {
      const all = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter((discussion) => !discussion.isForm && findApplicablePosition(discussion, diffRefs));
      if (!allCommentsReady.value) return all;
      return [
        ...all.map(withDraftReplies),
        ...draftNotes.findDraftsAsDiscussionsForFile({
          oldPath,
          newPath,
          diffRefs,
          isLatestVersion,
        }),
      ];
    };
  });

  const findLinePositionsForFile = computed(() => {
    const { isLatestVersion } = versions;
    return ({ oldPath, newPath, diffRefs }) => {
      const positions = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter(isLineDiscussion)
        .map((discussion) => findApplicablePosition(discussion, diffRefs))
        .filter(Boolean);
      if (!allCommentsReady.value) return positions;
      return [
        ...positions,
        ...draftNotes
          .findDraftsAsLineDiscussionsForFile({ oldPath, newPath, diffRefs, isLatestVersion })
          .map((discussion) => discussion.position),
      ];
    };
  });

  const findLineDiscussionsForPosition = computed(() => {
    const { isLatestVersion } = versions;
    return ({ oldPath, newPath, oldLine, newLine, diffRefs }) => {
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
      const drafts = draftNotes.findDraftsForPosition({
        oldPath,
        newPath,
        oldLine,
        newLine,
        diffRefs,
        isLatestVersion,
      });
      if (!drafts.length) return enriched;
      const discussions = enriched.filter((discussion) => !discussion.isForm);
      const forms = enriched.filter((discussion) => discussion.isForm);
      return [...discussions, ...drafts, ...forms];
    };
  });

  const findAllFileDiscussionsForFile = computed(() => {
    const { isLatestVersion } = versions;
    return ({ oldPath, newPath, diffRefs }) => {
      const all = diffDiscussions
        .findAllDiscussionsForFile({ oldPath, newPath })
        .filter((d) => isFileDiscussion(d) && findApplicablePosition(d, diffRefs));
      if (!allCommentsReady.value) return all;
      return [
        ...all.map(withDraftReplies),
        ...draftNotes.findDraftsAsFileDiscussionsForFile({
          oldPath,
          newPath,
          diffRefs,
          isLatestVersion,
        }),
      ];
    };
  });

  const findAllImageDiscussionsForFile = computed(() => {
    const { isLatestVersion } = versions;
    return ({ oldPath, newPath, diffRefs }) => {
      const all = diffDiscussions
        .findAllImageDiscussionsForFile(oldPath, newPath)
        .filter((discussion) => findApplicablePosition(discussion, diffRefs));
      if (!allCommentsReady.value) return all;
      return [
        ...all.map(withDraftReplies),
        ...draftNotes.findDraftsAsImageDiscussionsForFile({
          oldPath,
          newPath,
          diffRefs,
          isLatestVersion,
        }),
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
    createImageDiscussion,
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
    lineRangeEditing,
    startLineRangeEditing,
    commitLineRangeEditing,
    cancelLineRangeEditing,
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
