import { createTestingPinia } from '@pinia/testing';
import { useMergeRequestDiscussions } from '~/merge_request/stores/merge_request_discussions';
import { useMergeRequestVersions } from '~/merge_request/stores/merge_request_versions';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useDiscussions } from '~/notes/store/discussions';
import { useNotes } from '~/notes/store/legacy_notes';
import { useMrNotes } from '~/mr_notes/store/legacy_mr_notes';
import { useMergeRequestDraftNotes } from '~/merge_request/stores/merge_request_draft_notes';

jest.mock('~/notes/store/legacy_notes');
jest.mock('~/merge_request/stores/merge_request_draft_notes');

describe('mergeRequestDiscussions store', () => {
  let store;
  let mockNotesStore;
  let mockDraftNotes;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    mockDraftNotes = {
      drafts: [],
      isPublishing: false,
      hasDrafts: false,
      draftsCount: 0,
      fetchDrafts: jest.fn().mockResolvedValue(),
      createNewDraft: jest.fn().mockResolvedValue(),
      addDraftToDiscussion: jest.fn().mockResolvedValue(),
      updateDraft: jest.fn().mockResolvedValue(),
      deleteDraft: jest.fn().mockResolvedValue(),
      publishReview: jest.fn().mockResolvedValue(),
      discardDrafts: jest.fn().mockResolvedValue(),
      findDraftsForDiscussion: jest.fn().mockReturnValue([]),
      findDraftsAsDiscussionsForFile: jest.fn().mockReturnValue([]),
      findDraftsAsLineDiscussionsForFile: jest.fn().mockReturnValue([]),
      findDraftsAsFileDiscussionsForFile: jest.fn().mockReturnValue([]),
      findDraftsAsImageDiscussionsForFile: jest.fn().mockReturnValue([]),
      findDraftsForPosition: jest.fn().mockReturnValue([]),
    };
    useMergeRequestDraftNotes.mockReturnValue(mockDraftNotes);
    mockNotesStore = {
      fetchNotes: jest.fn().mockResolvedValue(),
      fetchNotesPromise: null,
      // eslint-disable-next-line no-empty-function
      fetchNotesBatches: jest.fn(async function* generator() {}),
      addOrUpdateDiscussions: jest.fn(),
      createNewNote: jest.fn().mockResolvedValue({ id: 'new-1' }),
      saveNote: jest.fn().mockResolvedValue(),
      replyToDiscussion: jest.fn().mockResolvedValue({ discussion: { id: 'disc-1' } }),
      updateNote: jest.fn().mockResolvedValue({ id: 1, body: 'updated' }),
      deleteNote: jest.fn().mockResolvedValue(),
      toggleAwardRequest: jest.fn().mockResolvedValue(),
      toggleResolveNote: jest.fn().mockResolvedValue(),
      submitSuggestion: jest.fn().mockResolvedValue(),
      submitSuggestionBatch: jest.fn().mockResolvedValue(),
      toggleAllDiscussions: jest.fn(),
      allDiscussionsExpanded: false,
      getSuggestionsFilePaths: jest.fn().mockResolvedValue(),
      addSuggestionInfoToBatch: jest.fn(),
      removeSuggestionInfoFromBatch: jest.fn(),
      batchSuggestionsInfo: [],
      suggestionsCount: 0,
      noteableData: {
        create_note_path: '/api/notes',
        noteableType: 'MergeRequest',
        id: 42,
        diff_head_sha: 'abc123',
        targetType: 'merge_request',
        can_receive_suggestion: true,
      },
      notesData: { draftsPath: '/drafts' },
      getUserData: { id: 1 },
    };
    useNotes.mockReturnValue(mockNotesStore);
    useMergeRequestVersions().setVersions({
      sourceVersions: [{ selected: true, base_sha: 'base000', head_sha: 'head222' }],
      targetVersions: [{ selected: true, version_index: 1, start_sha: 'start111' }],
    });
    store = useMergeRequestDiscussions();
  });

  it.each([
    'setInitialDiscussions',
    'replaceDiscussion',
    'toggleDiscussionReplies',
    'expandDiscussionReplies',
    'startReplying',
    'stopReplying',
    'addNote',
    'updateNote',
    'updateNoteTextById',
    'editNote',
    'deleteNote',
    'addDiscussion',
    'deleteDiscussion',
    'setEditingMode',
    'requestLastNoteEditing',
    'toggleAward',
    'updateDiscussion',
    'collapseDiscussion',
    'expandDiscussion',
    'addNewLineDiscussionForm',
    'replaceDiscussionForm',
    'removeNewLineDiscussionForm',
    'setDiscussionFormText',
    'setNewLineDiscussionFormAutofocus',
    'setFileDiscussionsHidden',
    'expandFileDiscussions',
    'addNewFileDiscussionForm',
    'removeNewFileDiscussionForm',
    'createNewDiscussion',
    'createLineDiscussion',
    'createFileDiscussion',
    'replyToDiscussion',
    'saveNote',
    'destroyNote',
    'toggleAwardOnNote',
    'toggleResolveNote',
    'setPositionDiscussionsHidden',
    'createDraftLineDiscussion',
    'createDraftFileDiscussion',
    'addDraftToDiscussion',
    'submitSuggestion',
    'submitSuggestionBatch',
    'addSuggestionInfoToBatch',
    'removeSuggestionInfoFromBatch',
  ])('exposes %s action', (action) => {
    expect(store[action]).toEqual(expect.any(Function));
  });

  it.each([
    'findDiscussionsForFile',
    'findLinePositionsForFile',
    'findLineDiscussionsForPosition',
    'findAllFileDiscussionsForFile',
    'findAllImageDiscussionsForFile',
    'batchSuggestionsInfo',
    'suggestionsCount',
    'suggestionsFilePaths',
  ])('exposes %s getter', (getter) => {
    expect(store[getter]).toBeDefined();
  });

  describe('fetchNotes', () => {
    describe('when fetchNotesPromise is not set (generator path)', () => {
      const batch1 = [{ id: 'disc-1' }];
      const batch2 = [{ id: 'disc-2' }];

      beforeEach(() => {
        mockNotesStore.fetchNotesPromise = null;
        mockNotesStore.fetchNotesBatches = jest.fn(async function* generator() {
          yield batch1;
          yield batch2;
        });
        mockNotesStore.addOrUpdateDiscussions = jest.fn();
      });

      it('iterates batches and adds discussions to the store', async () => {
        await store.fetchNotes();
        expect(mockNotesStore.addOrUpdateDiscussions).toHaveBeenCalledWith(batch1);
        expect(mockNotesStore.addOrUpdateDiscussions).toHaveBeenCalledWith(batch2);
      });

      it('collapses resolved discussions after each batch', async () => {
        const resolvedDiscussion = { id: '1', resolvable: true, resolved: true };
        const unresolvedDiscussion = { id: '2', resolvable: true, resolved: false };
        useDiscussions().discussions = [resolvedDiscussion, unresolvedDiscussion];

        await store.fetchNotes();

        expect(resolvedDiscussion).toMatchObject({ hidden: true });
        expect(unresolvedDiscussion).not.toHaveProperty('hidden');
      });
    });

    describe('when fetchNotesPromise is already set (await path)', () => {
      it('awaits existing promise and collapses resolved discussions', async () => {
        mockNotesStore.fetchNotesPromise = Promise.resolve();

        const resolvedDiscussion = { id: '1', resolvable: true, resolved: true };
        const nonResolvableDiscussion = { id: '3', resolvable: false };
        useDiscussions().discussions = [resolvedDiscussion, nonResolvableDiscussion];

        await store.fetchNotes();

        expect(resolvedDiscussion).toMatchObject({ hidden: true });
        expect(nonResolvableDiscussion).not.toHaveProperty('hidden');
      });

      it('does not call fetchNotesBatches', async () => {
        mockNotesStore.fetchNotesPromise = Promise.resolve();
        mockNotesStore.fetchNotesBatches = jest.fn();

        await store.fetchNotes();

        expect(mockNotesStore.fetchNotesBatches).not.toHaveBeenCalled();
      });
    });
  });

  describe('createNewDiscussion', () => {
    it('delegates to notes store createNewNote', async () => {
      await store.createNewDiscussion({ note: 'test' });
      expect(mockNotesStore.createNewNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: { note: { note: 'test' } },
      });
    });
  });

  describe('createLineDiscussion', () => {
    it('delegates to notes store saveNote and removes the form', async () => {
      const formDiscussion = {
        id: 'form-1',
        isForm: true,
        position: { old_line: 1 },
        lineChange: { change: 'added', position: 'new' },
        lineCode: 'hash_0_1',
      };
      useDiffDiscussions().discussionForms.push(formDiscussion);

      await store.createLineDiscussion(formDiscussion, 'test');

      expect(mockNotesStore.saveNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: {
          view: useDiffsView().viewType,
          line_type: 'new',
          merge_request_diff_head_sha: 'head222',
          note_project_id: '',
          target_type: 'merge_request',
          target_id: 42,
          return_discussion: true,
          note: {
            note: 'test',
            position: JSON.stringify({
              base_sha: 'base000',
              start_sha: 'start111',
              head_sha: 'head222',
              old_line: 1,
              position_type: 'text',
              ignore_whitespace_change: !useDiffsView().showWhitespace,
            }),
            noteable_type: 'MergeRequest',
            noteable_id: 42,
            commit_id: null,
            type: 'DiffNote',
            line_code: 'hash_0_1',
          },
        },
      });
      expect(useDiffDiscussions().discussionForms).not.toContainEqual(formDiscussion);
    });
  });

  describe('addNewLineDiscussionForm', () => {
    const lineRange = {
      start: { old_line: null, new_line: 5 },
      end: { old_line: null, new_line: 5 },
    };

    it('sets canSuggest to true for added lines', () => {
      store.addNewLineDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
        lineRange,
        lineChange: { change: 'added', position: 'new' },
        lineCode: 'abc_0_5',
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.canSuggest).toBe(true);
    });

    it('sets canSuggest to false for removed lines', () => {
      store.addNewLineDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
        lineRange,
        lineChange: { change: 'removed', position: 'old' },
        lineCode: 'abc_5_0',
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.canSuggest).toBe(false);
    });

    it('builds previewParams when diffRefs and newPath and newLine are present', () => {
      store.addNewLineDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
        lineRange,
        lineChange: { change: 'added', position: 'new' },
        lineCode: 'abc_0_5',
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.previewParams).toStrictEqual({
        preview_suggestions: true,
        line: 5,
        file_path: 'a.rb',
        base_sha: 'base000',
        start_sha: 'start111',
        head_sha: 'head222',
      });
    });

    it('sets previewParams to null for removed lines', () => {
      store.addNewLineDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
        lineRange,
        lineChange: { change: 'removed', position: 'old' },
        lineCode: 'abc_5_0',
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.previewParams).toBeNull();
    });
  });

  describe('commit view forms', () => {
    const commitDiffRefs = { base_sha: 'parent', start_sha: 'parent', head_sha: 'commit_sha' };

    beforeEach(() => {
      useMergeRequestVersions().setCommit({
        id: 'commit_sha',
        diff_refs: commitDiffRefs,
      });
    });

    it('passes commitId to line discussion form', () => {
      store.addNewLineDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
        lineRange: { start: { old_line: null, new_line: 5 }, end: { old_line: null, new_line: 5 } },
        lineChange: { change: 'added', position: 'new' },
        lineCode: 'abc_0_5',
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.commitId).toBe('commit_sha');
    });

    it('passes commitId to file discussion form', () => {
      store.addNewFileDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.commitId).toBe('commit_sha');
    });

    it('merges caller extraOptions in file discussion form', () => {
      store.addNewFileDiscussionForm({
        oldPath: 'a.rb',
        newPath: 'a.rb',
        extraOptions: { custom: 'value' },
      });
      const form = useDiffDiscussions().discussionForms[0];
      expect(form.custom).toBe('value');
      expect(form.commitId).toBe('commit_sha');
    });
  });

  describe('createFileDiscussion', () => {
    it('delegates to notes store saveNote and removes the form', async () => {
      const position = {
        position_type: 'file',
        old_path: 'file.js',
        new_path: 'file.js',
        old_line: null,
        new_line: null,
      };
      const formDiscussion = { id: 'form-1', isForm: true, position };
      useDiffDiscussions().discussionForms.push(formDiscussion);

      await store.createFileDiscussion(formDiscussion, 'test');

      expect(mockNotesStore.saveNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: expect.objectContaining({
          note: expect.objectContaining({
            note: 'test',
            position: expect.stringContaining('"position_type":"file"'),
          }),
        }),
      });
      expect(useDiffDiscussions().discussionForms).not.toContainEqual(formDiscussion);
    });
  });

  describe('replyToDiscussion', () => {
    it('delegates to notes store saveNote with reply data', async () => {
      const discussion = { id: 'disc-1', reply_id: 'reply-1' };

      await store.replyToDiscussion(discussion, 'reply text');

      expect(mockNotesStore.saveNote).toHaveBeenCalledWith({
        endpoint: '/api/notes',
        data: {
          in_reply_to_discussion_id: 'reply-1',
          target_type: 'merge_request',
          note: { note: 'reply text' },
          merge_request_diff_head_sha: 'head222',
        },
      });
    });
  });

  describe('saveNote', () => {
    it('delegates to notes store updateNote', async () => {
      const note = { id: 1, path: '/note/1', noteable_id: 10 };

      await store.saveNote(note, 'updated');

      expect(mockNotesStore.updateNote).toHaveBeenCalledWith({
        endpoint: '/note/1',
        note: {
          target_type: 'merge_request',
          target_id: 10,
          note: { note: 'updated' },
        },
      });
    });
  });

  describe('destroyNote', () => {
    it('delegates to notes store deleteNote', async () => {
      const note = { id: 1, path: '/note/1' };

      await store.destroyNote(note);

      expect(mockNotesStore.deleteNote).toHaveBeenCalledWith(note);
    });
  });

  describe('toggleAwardOnNote', () => {
    it('delegates to notes store toggleAwardRequest', async () => {
      const note = { id: 1, toggle_award_path: '/award/1' };

      await store.toggleAwardOnNote(note, 'thumbsup');

      expect(mockNotesStore.toggleAwardRequest).toHaveBeenCalledWith({
        endpoint: '/award/1',
        awardName: 'thumbsup',
        noteId: 1,
      });
    });
  });

  describe('toggleResolveNote', () => {
    it('delegates to the legacy notes store', async () => {
      const discussion = {
        id: 'discussion-1',
        resolved: false,
        resolve_path: '/resolve/path',
      };

      await store.toggleResolveNote(discussion);

      expect(mockNotesStore.toggleResolveNote).toHaveBeenCalledWith({
        endpoint: '/resolve/path',
        isResolved: false,
        discussion: true,
        discussionId: 'discussion-1',
      });
    });
  });

  describe('toggleAllVisibleDiscussions', () => {
    it('toggles diff discussions when on the diffs page', () => {
      useMrNotes().setActiveTab('diffs');
      useDiscussions().setInitialDiscussions([
        { id: 'd1', diff_discussion: true, hidden: false, notes: [] },
        { id: 'd2', diff_discussion: true, hidden: false, notes: [] },
      ]);

      store.toggleAllVisibleDiscussions();

      expect(useDiscussions().discussions[0].hidden).toBe(true);
      expect(useDiscussions().discussions[1].hidden).toBe(true);
    });

    it('delegates to legacy notes store toggleAllDiscussions when not on the diffs page', () => {
      useMrNotes().setActiveTab('show');

      store.toggleAllVisibleDiscussions();

      expect(mockNotesStore.toggleAllDiscussions).toHaveBeenCalled();
    });
  });

  describe('allVisibleDiscussionsExpanded', () => {
    it('reflects diff discussions state on the diffs page', () => {
      useMrNotes().setActiveTab('diffs');
      useDiscussions().setInitialDiscussions([
        { id: 'd1', diff_discussion: true, hidden: false, notes: [] },
        { id: 'd2', diff_discussion: true, hidden: true, notes: [] },
      ]);

      expect(store.allVisibleDiscussionsExpanded).toBe(false);
    });

    it('reflects legacy notes allDiscussionsExpanded when not on the diffs page', () => {
      useMrNotes().setActiveTab('show');
      mockNotesStore.allDiscussionsExpanded = true;

      expect(store.allVisibleDiscussionsExpanded).toBe(true);
    });
  });

  describe('setFileDiscussionsHidden', () => {
    it('hides discussions for the file', () => {
      useDiscussions().setInitialDiscussions([
        {
          id: 'd1',
          diff_discussion: true,
          position: { old_path: 'a.js', new_path: 'a.js' },
          notes: [],
        },
      ]);

      store.setFileDiscussionsHidden('a.js', 'a.js', true);

      expect(useDiscussions().discussions[0].hidden).toBe(true);
    });
  });

  describe('setPositionDiscussionsHidden', () => {
    it('hides discussions for the position', () => {
      const pos = { oldPath: 'a.js', newPath: 'a.js', oldLine: 1, newLine: 1 };
      useDiscussions().setInitialDiscussions([
        {
          id: 'd1',
          diff_discussion: true,
          position: {
            old_path: 'a.js',
            new_path: 'a.js',
            old_line: 1,
            new_line: 1,
            position_type: 'text',
          },
          notes: [],
        },
      ]);

      store.setPositionDiscussionsHidden(pos, true);

      expect(useDiscussions().discussions[0].hidden).toBe(true);
    });
  });

  describe('findDraftsForDiscussion', () => {
    it('returns empty array when allCommentsReady is false', () => {
      mockDraftNotes.findDraftsForDiscussion.mockReturnValue([{ id: 1 }]);

      expect(store.findDraftsForDiscussion('disc-1')).toEqual([]);
    });

    it('delegates to draftNotes after fetchNotesAndDrafts', async () => {
      mockDraftNotes.findDraftsForDiscussion.mockReturnValue([{ id: 1 }]);

      await store.fetchNotesAndDrafts();

      expect(store.findDraftsForDiscussion('disc-1')).toEqual([{ id: 1 }]);
      expect(mockDraftNotes.findDraftsForDiscussion).toHaveBeenCalledWith('disc-1');
    });
  });

  describe('createDraftLineDiscussion', () => {
    const formDiscussion = {
      id: 'form-1',
      isForm: true,
      position: { old_line: 1, new_line: 1, old_path: 'a.rb', new_path: 'a.rb' },
      lineCode: 'hash_0_1',
    };

    it('calls createNewDraft with correct params and removes the form', async () => {
      useDiffDiscussions().discussionForms.push(formDiscussion);

      await store.createDraftLineDiscussion(formDiscussion, 'draft comment');

      expect(mockDraftNotes.createNewDraft).toHaveBeenCalledWith({
        endpoint: '/drafts',
        data: {
          note: {
            note: 'draft comment',
            position: JSON.stringify({
              base_sha: 'base000',
              start_sha: 'start111',
              head_sha: 'head222',
              old_line: 1,
              new_line: 1,
              old_path: 'a.rb',
              new_path: 'a.rb',
              position_type: 'text',
              ignore_whitespace_change: !useDiffsView().showWhitespace,
            }),
            type: 'DiffNote',
            line_code: 'hash_0_1',
          },
        },
      });
      expect(useDiffDiscussions().discussionForms).not.toContainEqual(formDiscussion);
    });
  });

  describe('createDraftFileDiscussion', () => {
    const formDiscussion = {
      id: 'form-1',
      isForm: true,
      position: { position_type: 'file', old_path: 'file.js', new_path: 'file.js' },
    };

    it('calls createNewDraft and removes the file form', async () => {
      useDiffDiscussions().discussionForms.push(formDiscussion);

      await store.createDraftFileDiscussion(formDiscussion, 'draft file comment');

      expect(mockDraftNotes.createNewDraft).toHaveBeenCalledWith({
        endpoint: '/drafts',
        data: {
          note: expect.objectContaining({
            note: 'draft file comment',
            position: expect.stringContaining('"position_type":"file"'),
          }),
        },
      });
      expect(useDiffDiscussions().discussionForms).not.toContainEqual(formDiscussion);
    });
  });

  describe('addDraftToDiscussion', () => {
    it('calls addDraftToDiscussion with correct params', async () => {
      const discussion = { id: 'disc-1', reply_id: 'reply-1' };

      await store.addDraftToDiscussion(discussion, 'draft reply');

      expect(mockDraftNotes.addDraftToDiscussion).toHaveBeenCalledWith({
        endpoint: '/drafts',
        data: {
          in_reply_to_discussion_id: 'reply-1',
          draft_note: { note: 'draft reply', resolve_discussion: false },
          merge_request_diff_head_sha: 'head222',
        },
      });
    });
  });

  describe('version-aware discussion matching', () => {
    const diffRefs = { base_sha: 'base000', head_sha: 'head222', start_sha: 'start111' };
    const otherRefs = { base_sha: 'other', head_sha: 'other', start_sha: 'other' };
    const filePaths = { oldPath: 'a.js', newPath: 'a.js' };
    const makePos = (refs, line = 5) => ({
      old_path: 'a.js',
      new_path: 'a.js',
      old_line: line,
      new_line: line,
      position_type: 'text',
      ...refs,
    });

    function makeDiscussion(id, overrides = {}) {
      return {
        id,
        diff_discussion: true,
        position: makePos(diffRefs),
        original_position: makePos(diffRefs),
        notes: [],
        ...overrides,
      };
    }

    describe('findDiscussionsForFile', () => {
      it.each([
        ['includes', diffRefs, 1],
        ['excludes', otherRefs, 0],
      ])('%s discussions based on SHA match', (_, refs, expected) => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('d', { position: makePos(refs), original_position: makePos(refs) }),
        ]);

        expect(store.findDiscussionsForFile(filePaths)).toHaveLength(expected);
      });

      it('excludes form discussions', () => {
        store.addNewLineDiscussionForm({
          ...filePaths,
          lineRange: { start: { old_line: 1, new_line: 1 }, end: { old_line: 1, new_line: 1 } },
        });

        expect(store.findDiscussionsForFile(filePaths)).toHaveLength(0);
      });

      it('excludes drafts until comments are ready', () => {
        mockDraftNotes.findDraftsAsDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true },
        ]);

        expect(store.findDiscussionsForFile(filePaths)).toHaveLength(0);
      });

      it('includes drafts after fetchNotesAndDrafts', async () => {
        mockDraftNotes.findDraftsAsDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true },
        ]);

        await store.fetchNotesAndDrafts();

        expect(store.findDiscussionsForFile(filePaths)).toHaveLength(1);
      });

      it('appends draft replies to discussion notes', async () => {
        const draftReply = { id: 'draft-reply', isDraft: true };
        useDiscussions().setInitialDiscussions([
          makeDiscussion('d', { position: makePos(diffRefs), notes: [{ id: 'n1' }] }),
        ]);
        mockDraftNotes.findDraftsForDiscussion.mockReturnValue([draftReply]);

        await store.fetchNotesAndDrafts();

        const [discussion] = store.findDiscussionsForFile(filePaths);
        expect(discussion.notes).toHaveLength(2);
        expect(discussion.notes[1]).toBe(draftReply);
      });
    });

    describe('findLinePositionsForFile', () => {
      it('swaps position to applicable version', () => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('swap', {
            position: makePos(otherRefs, 99),
            original_position: makePos(diffRefs),
          }),
        ]);

        const [result] = store.findLinePositionsForFile(filePaths);
        expect(result.old_line).toBe(5);
        expect(result).toMatchObject(diffRefs);
      });

      it('excludes non-line discussions', () => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('file-disc', {
            position: { position_type: 'file', old_path: 'a.js', new_path: 'a.js', ...diffRefs },
            original_position: {
              position_type: 'file',
              old_path: 'a.js',
              new_path: 'a.js',
              ...diffRefs,
            },
          }),
        ]);

        expect(store.findLinePositionsForFile(filePaths)).toHaveLength(0);
      });

      it('excludes line drafts until comments are ready', () => {
        mockDraftNotes.findDraftsAsLineDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true, position: makePos(diffRefs) },
        ]);

        expect(store.findLinePositionsForFile(filePaths)).toHaveLength(0);
      });

      it('includes line drafts after fetchNotesAndDrafts', async () => {
        mockDraftNotes.findDraftsAsLineDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true, position: makePos(diffRefs) },
        ]);

        await store.fetchNotesAndDrafts();

        expect(store.findLinePositionsForFile(filePaths)).toHaveLength(1);
      });
    });

    describe('findLineDiscussionsForPosition', () => {
      it('returns discussions matching the given position', () => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('match', {
            position: makePos(diffRefs, 5),
            original_position: makePos(diffRefs, 5),
          }),
          makeDiscussion('no-match', {
            position: makePos(diffRefs, 10),
            original_position: makePos(diffRefs, 10),
          }),
        ]);

        const result = store.findLineDiscussionsForPosition({
          ...filePaths,
          oldLine: 5,
          newLine: 5,
        });
        expect(result).toHaveLength(1);
        expect(result[0].id).toBe('match');
      });

      it('swaps position to applicable version for matching', () => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('swap', {
            position: makePos(otherRefs, 99),
            original_position: makePos(diffRefs, 5),
          }),
        ]);

        const result = store.findLineDiscussionsForPosition({
          ...filePaths,
          oldLine: 5,
          newLine: 5,
        });
        expect(result).toHaveLength(1);
        expect(result[0].id).toBe('swap');
      });

      it('excludes drafts until comments are ready', () => {
        mockDraftNotes.findDraftsForPosition.mockReturnValue([{ id: 'draft_1', isDraft: true }]);

        expect(
          store.findLineDiscussionsForPosition({ ...filePaths, oldLine: 5, newLine: 5 }),
        ).toHaveLength(0);
      });

      it('includes drafts after fetchNotesAndDrafts', async () => {
        mockDraftNotes.findDraftsForPosition.mockReturnValue([{ id: 'draft_1', isDraft: true }]);

        await store.fetchNotesAndDrafts();

        const result = store.findLineDiscussionsForPosition({
          ...filePaths,
          oldLine: 5,
          newLine: 5,
        });
        expect(result).toHaveLength(1);
      });

      it('appends draft replies to discussion notes', async () => {
        const draftReply = { id: 'draft-reply', isDraft: true };
        useDiscussions().setInitialDiscussions([
          makeDiscussion('d', { position: makePos(diffRefs), notes: [{ id: 'n1' }] }),
        ]);
        mockDraftNotes.findDraftsForDiscussion.mockReturnValue([draftReply]);

        await store.fetchNotesAndDrafts();

        const [discussion] = store.findLineDiscussionsForPosition({
          ...filePaths,
          oldLine: 5,
          newLine: 5,
        });
        expect(discussion.notes).toHaveLength(2);
        expect(discussion.notes[1]).toBe(draftReply);
      });
    });

    describe('findAllFileDiscussionsForFile', () => {
      const filePos = {
        position_type: 'file',
        old_path: 'a.js',
        new_path: 'a.js',
        ...diffRefs,
      };

      it('returns file-level discussions', () => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('file-disc', {
            position: filePos,
            original_position: filePos,
          }),
        ]);

        expect(store.findAllFileDiscussionsForFile(filePaths)).toHaveLength(1);
      });

      it('excludes line discussions', () => {
        useDiscussions().setInitialDiscussions([
          makeDiscussion('line-disc', {
            position: makePos(diffRefs),
            original_position: makePos(diffRefs),
          }),
        ]);

        expect(store.findAllFileDiscussionsForFile(filePaths)).toHaveLength(0);
      });

      it('excludes file drafts until comments are ready', () => {
        mockDraftNotes.findDraftsAsFileDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true },
        ]);

        expect(store.findAllFileDiscussionsForFile(filePaths)).toHaveLength(0);
      });

      it('includes file drafts after fetchNotesAndDrafts', async () => {
        mockDraftNotes.findDraftsAsFileDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true },
        ]);

        await store.fetchNotesAndDrafts();

        expect(store.findAllFileDiscussionsForFile(filePaths)).toHaveLength(1);
      });

      it('appends draft replies to discussion notes', async () => {
        const draftReply = { id: 'draft-reply', isDraft: true };
        useDiscussions().setInitialDiscussions([
          makeDiscussion('d', {
            position: filePos,
            original_position: filePos,
            notes: [{ id: 'n1' }],
          }),
        ]);
        mockDraftNotes.findDraftsForDiscussion.mockReturnValue([draftReply]);

        await store.fetchNotesAndDrafts();

        const [discussion] = store.findAllFileDiscussionsForFile(filePaths);
        expect(discussion.notes).toHaveLength(2);
        expect(discussion.notes[1]).toBe(draftReply);
      });
    });

    describe('findAllImageDiscussionsForFile', () => {
      it.each([
        ['returns', diffRefs, 1],
        ['excludes', otherRefs, 0],
      ])('%s image discussions with %s SHAs', (_, refs, expected) => {
        useDiscussions().setInitialDiscussions([
          {
            id: 'img',
            notes: [
              { position: { position_type: 'image', old_path: 'a.js', new_path: 'a.js', ...refs } },
            ],
            position: { position_type: 'image', old_path: 'a.js', new_path: 'a.js', ...refs },
            original_position: {
              position_type: 'image',
              old_path: 'a.js',
              new_path: 'a.js',
              ...refs,
            },
          },
        ]);

        expect(store.findAllImageDiscussionsForFile('a.js', 'a.js')).toHaveLength(expected);
      });

      it('excludes image drafts until comments are ready', () => {
        mockDraftNotes.findDraftsAsImageDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true },
        ]);

        expect(store.findAllImageDiscussionsForFile('a.js', 'a.js')).toHaveLength(0);
      });

      it('includes image drafts after fetchNotesAndDrafts', async () => {
        mockDraftNotes.findDraftsAsImageDiscussionsForFile.mockReturnValue([
          { id: 'draft_1', isDraft: true },
        ]);

        await store.fetchNotesAndDrafts();

        expect(store.findAllImageDiscussionsForFile('a.js', 'a.js')).toHaveLength(1);
      });

      it('appends draft replies to discussion notes', async () => {
        const draftReply = { id: 'draft-reply', isDraft: true };
        const imagePos = {
          position_type: 'image',
          old_path: 'a.js',
          new_path: 'a.js',
          ...diffRefs,
        };
        useDiscussions().setInitialDiscussions([
          {
            id: 'img',
            notes: [{ id: 'n1', position: imagePos }],
            position: imagePos,
            original_position: imagePos,
          },
        ]);
        mockDraftNotes.findDraftsForDiscussion.mockReturnValue([draftReply]);

        await store.fetchNotesAndDrafts();

        const [discussion] = store.findAllImageDiscussionsForFile('a.js', 'a.js');
        expect(discussion.notes).toHaveLength(2);
        expect(discussion.notes[1]).toBe(draftReply);
      });
    });
  });
});
