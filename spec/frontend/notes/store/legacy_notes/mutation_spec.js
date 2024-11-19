import { createPinia, setActivePinia } from 'pinia';
import { DISCUSSION_NOTE, DESC } from '~/notes/constants';
import * as types from '~/notes/stores/mutation_types';
import { useNotes } from '~/notes/store/legacy_notes';
import {
  note,
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  notesWithDescriptionChanges,
  batchSuggestionsInfoMock,
} from '../../mock_data';

const RESOLVED_NOTE = { resolvable: true, resolved: true };
const UNRESOLVED_NOTE = { resolvable: true, resolved: false };
const SYSTEM_NOTE = { resolvable: false, resolved: false };
const WEIRD_NOTE = { resolvable: false, resolved: true };

describe('Notes Store mutations', () => {
  let store;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useNotes();
  });

  describe('ADD_NEW_NOTE', () => {
    let noteData;

    beforeEach(() => {
      noteData = {
        expanded: true,
        id: note.discussion_id,
        individual_note: true,
        notes: [note],
        reply_id: note.discussion_id,
      };
    });

    it('should add a new note to an array of notes', () => {
      store[types.ADD_NEW_NOTE](note);
      expect(store.discussions).toStrictEqual([noteData]);
      expect(store.discussions.length).toBe(1);
    });

    it('should not add the same note to the notes array', () => {
      store[types.ADD_NEW_NOTE](note);
      store[types.ADD_NEW_NOTE](note);

      expect(store.discussions.length).toBe(1);
    });

    it('trims first character from truncated_diff_lines', () => {
      store[types.ADD_NEW_NOTE]({
        discussion: {
          notes: [{ ...note }],
          truncated_diff_lines: [{ text: '+a', rich_text: '+<span>a</span>' }],
        },
      });

      expect(store.discussions[0].truncated_diff_lines).toEqual([{ rich_text: '<span>a</span>' }]);
    });
  });

  describe('ADD_NEW_REPLY_TO_DISCUSSION', () => {
    const newReply = { ...note, discussion_id: discussionMock.id };

    beforeEach(() => {
      store.discussions = [{ ...discussionMock }];
    });

    it('should add a reply to a specific discussion', () => {
      store[types.ADD_NEW_REPLY_TO_DISCUSSION](newReply);

      expect(store.discussions[0].notes.length).toEqual(4);
    });

    it('should not add the note if it already exists in the discussion', () => {
      store[types.ADD_NEW_REPLY_TO_DISCUSSION](newReply);
      store[types.ADD_NEW_REPLY_TO_DISCUSSION](newReply);

      expect(store.discussions[0].notes.length).toEqual(4);
    });
  });

  describe('DELETE_NOTE', () => {
    it('should delete a note', () => {
      store.$patch({ discussions: [discussionMock] });
      const toDelete = discussionMock.notes[0];
      const lengthBefore = discussionMock.notes.length;

      store[types.DELETE_NOTE](toDelete);

      expect(store.discussions[0].notes.length).toEqual(lengthBefore - 1);
    });
  });

  describe('EXPAND_DISCUSSION', () => {
    it('should expand a collapsed discussion', () => {
      const discussion = { ...discussionMock, expanded: false };

      store.$patch({
        discussions: [discussion],
      });

      store[types.EXPAND_DISCUSSION]({ discussionId: discussion.id });

      expect(store.discussions[0].expanded).toEqual(true);
    });
  });

  describe('COLLAPSE_DISCUSSION', () => {
    it('should collapse an expanded discussion', () => {
      const discussion = { ...discussionMock, expanded: true };

      store.$patch({
        discussions: [discussion],
      });

      store[types.COLLAPSE_DISCUSSION]({ discussionId: discussion.id });

      expect(store.discussions[0].expanded).toEqual(false);
    });
  });

  describe('REMOVE_PLACEHOLDER_NOTES', () => {
    it('should remove all placeholder individual notes', () => {
      const placeholderNote = { ...individualNote, isPlaceholderNote: true };
      store.$patch({ discussions: [placeholderNote] });

      store[types.REMOVE_PLACEHOLDER_NOTES]();

      expect(store.discussions).toEqual([]);
    });

    it.each`
      discussionType | discussion
      ${'initial'}   | ${individualNote}
      ${'continued'} | ${discussionMock}
    `('should remove all placeholder notes from $discussionType discussions', ({ discussion }) => {
      const lengthBefore = discussion.notes.length;

      const placeholderNote = { ...individualNote, isPlaceholderNote: true };
      discussion.notes.push(placeholderNote);

      store.$patch({
        discussions: [discussion],
      });

      store[types.REMOVE_PLACEHOLDER_NOTES]();

      expect(store.discussions[0].notes.length).toEqual(lengthBefore);
    });
  });

  describe('SET_NOTES_DATA', () => {
    it('should set an object with notesData', () => {
      store.$patch({
        notesData: {},
      });

      store[types.SET_NOTES_DATA](notesDataMock);

      expect(store.notesData).toEqual(notesDataMock);
    });
  });

  describe('SET_NOTEABLE_DATA', () => {
    it('should set the issue data', () => {
      store.$patch({
        noteableData: {},
      });

      store[types.SET_NOTEABLE_DATA](noteableDataMock);

      expect(store.noteableData).toEqual(noteableDataMock);
    });
  });

  describe('SET_USER_DATA', () => {
    it('should set the user data', () => {
      store.$patch({
        userData: {},
      });

      store[types.SET_USER_DATA](userDataMock);

      expect(store.userData).toEqual(userDataMock);
    });
  });

  describe('CLEAR_DISCUSSIONS', () => {
    it('should set discussions to an empty array', () => {
      store.$patch({
        discussions: [discussionMock],
      });

      store[types.CLEAR_DISCUSSIONS]();

      expect(store.discussions).toEqual([]);
    });
  });

  describe('ADD_OR_UPDATE_DISCUSSIONS', () => {
    it('should set the initial notes received', () => {
      store.$patch({
        discussions: [],
      });
      const legacyNote = {
        id: 2,
        individual_note: true,
        notes: [
          {
            id: 100,
            note: '1',
          },
          {
            id: 101,
            note: '2',
          },
        ],
      };

      store[types.ADD_OR_UPDATE_DISCUSSIONS]([note, legacyNote]);

      expect(store.discussions[0].id).toEqual(note.id);
      expect(store.discussions[1].notes[0].note).toBe(legacyNote.notes[0].note);
      expect(store.discussions[2].notes[0].note).toBe(legacyNote.notes[1].note);
      expect(store.discussions.length).toEqual(3);
    });

    it('adds truncated_diff_lines if discussion is a diffFile', () => {
      store.$patch({
        discussions: [],
      });

      store[types.ADD_OR_UPDATE_DISCUSSIONS]([
        {
          ...note,
          diff_file: {
            file_hash: 'a',
          },
          truncated_diff_lines: [{ text: '+a', rich_text: '+<span>a</span>' }],
        },
      ]);

      expect(store.discussions[0].truncated_diff_lines).toEqual([{ rich_text: '<span>a</span>' }]);
    });

    it('adds empty truncated_diff_lines when not in discussion', () => {
      store.$patch({
        discussions: [],
      });

      store[types.ADD_OR_UPDATE_DISCUSSIONS]([
        {
          ...note,
          diff_file: {
            file_hash: 'a',
          },
        },
      ]);

      expect(store.discussions[0].truncated_diff_lines).toEqual([]);
    });
  });

  describe('SET_LAST_FETCHED_AT', () => {
    it('should set timestamp', () => {
      store.$patch({
        lastFetchedAt: [],
      });

      store[types.SET_LAST_FETCHED_AT]('timestamp');

      expect(store.lastFetchedAt).toEqual('timestamp');
    });
  });

  describe('SET_TARGET_NOTE_HASH', () => {
    it('should set the note hash', () => {
      store.$patch({
        targetNoteHash: [],
      });

      store[types.SET_TARGET_NOTE_HASH]('hash');

      expect(store.targetNoteHash).toEqual('hash');
    });
  });

  describe('SHOW_PLACEHOLDER_NOTE', () => {
    it('should set a placeholder note', () => {
      store.$patch({
        discussions: [],
      });
      store[types.SHOW_PLACEHOLDER_NOTE](note);

      expect(store.discussions[0].isPlaceholderNote).toEqual(true);
    });
  });

  describe('TOGGLE_AWARD', () => {
    it('should add award if user has not reacted yet', () => {
      store.$patch({
        discussions: [note],
        userData: userDataMock,
      });

      const data = {
        note,
        awardName: 'cartwheel',
      };

      store[types.TOGGLE_AWARD](data);
      const lastIndex = store.discussions[0].award_emoji.length - 1;

      expect(store.discussions[0].award_emoji[lastIndex]).toEqual({
        name: 'cartwheel',
        user: { id: userDataMock.id, name: userDataMock.name, username: userDataMock.username },
      });
    });

    it('should remove award if user already reacted', () => {
      store.$patch({
        discussions: [note],
        userData: {
          id: 1,
          name: 'Administrator',
          username: 'root',
        },
      });

      const data = {
        note,
        awardName: 'bath_tone3',
      };
      store[types.TOGGLE_AWARD](data);

      expect(store.discussions[0].award_emoji.length).toEqual(2);
    });
  });

  describe('TOGGLE_DISCUSSION', () => {
    it('should open a closed discussion', () => {
      const discussion = { ...discussionMock, expanded: false };

      store.$patch({
        discussions: [discussion],
      });

      store[types.TOGGLE_DISCUSSION]({ discussionId: discussion.id });

      expect(store.discussions[0].expanded).toEqual(true);
    });

    it('should close a opened discussion', () => {
      store.$patch({
        discussions: [discussionMock],
      });

      store[types.TOGGLE_DISCUSSION]({ discussionId: discussionMock.id });

      expect(store.discussions[0].expanded).toEqual(false);
    });

    it('forces a discussions expanded state', () => {
      store.$patch({
        discussions: [{ ...discussionMock, expanded: false }],
      });

      store[types.TOGGLE_DISCUSSION]({ discussionId: discussionMock.id, forceExpanded: true });

      expect(store.discussions[0].expanded).toEqual(true);
    });
  });

  describe('SET_EXPAND_DISCUSSIONS', () => {
    it('should succeed when discussions are null', () => {
      expect(() =>
        store[types.SET_EXPAND_DISCUSSIONS]({ discussionIds: null, expanded: true }),
      ).not.toThrow();
    });

    it('should succeed when discussions are empty', () => {
      store[types.SET_EXPAND_DISCUSSIONS]({ discussionIds: [], expanded: true });

      expect(store.discussions).toEqual([]);
    });

    it('should open all closed discussions', () => {
      const discussion1 = { ...discussionMock, id: 0, expanded: false };
      const discussion2 = { ...discussionMock, id: 1, expanded: true };
      const discussionIds = [discussion1.id, discussion2.id];

      store.$patch({ discussions: [discussion1, discussion2] });

      store[types.SET_EXPAND_DISCUSSIONS]({ discussionIds, expanded: true });

      store.discussions.forEach((discussion) => {
        expect(discussion.expanded).toEqual(true);
      });
    });

    it('should close all opened discussions', () => {
      const discussion1 = { ...discussionMock, id: 0, expanded: false };
      const discussion2 = { ...discussionMock, id: 1, expanded: true };
      const discussionIds = [discussion1.id, discussion2.id];

      store.$patch({ discussions: [discussion1, discussion2] });

      store[types.SET_EXPAND_DISCUSSIONS]({ discussionIds, expanded: false });

      store.discussions.forEach((discussion) => {
        expect(discussion.expanded).toEqual(false);
      });
    });
  });

  describe('SET_RESOLVING_DISCUSSION', () => {
    it('should set resolving discussion state', () => {
      store[types.SET_RESOLVING_DISCUSSION](true);

      expect(store.isResolvingDiscussion).toEqual(true);
    });
  });

  describe('UPDATE_NOTE', () => {
    it('should update a note', () => {
      store.$patch({
        discussions: [individualNote],
      });

      const updated = { ...individualNote.notes[0], note: 'Foo' };

      store[types.UPDATE_NOTE](updated);

      expect(store.discussions[0].notes[0].note).toEqual('Foo');
    });

    it('does not update existing note if it matches', () => {
      const originalNote = { ...individualNote, individual_note: false };
      store.$patch({
        discussions: [originalNote],
      });

      const updated = individualNote.notes[0];

      store[types.UPDATE_NOTE](updated);

      expect(store.discussions[0]).toStrictEqual(originalNote);
    });

    it('transforms an individual note to discussion', () => {
      store.$patch({
        discussions: [individualNote],
      });

      const transformedNote = {
        ...individualNote.notes[0],
        type: DISCUSSION_NOTE,
        resolvable: true,
      };

      store[types.UPDATE_NOTE](transformedNote);

      expect(store.discussions[0].individual_note).toEqual(false);
      expect(store.discussions[0].resolvable).toEqual(true);
    });

    it('copies resolve state to discussion', () => {
      store.$patch({ discussions: [{ ...discussionMock }] });

      const resolvedNote = {
        ...discussionMock.notes[0],
        resolvable: true,
        resolved: true,
        resolved_at: '2017-08-02T10:51:58.559Z',
        resolved_by: discussionMock.notes[0].author,
        resolved_by_push: false,
      };

      store[types.UPDATE_NOTE](resolvedNote);

      expect(store.discussions[0].resolved).toEqual(resolvedNote.resolved);
      expect(store.discussions[0].resolved_at).toEqual(resolvedNote.resolved_at);
      expect(store.discussions[0].resolved_by).toEqual(resolvedNote.resolved_by);
      expect(store.discussions[0].resolved_by_push).toEqual(resolvedNote.resolved_by_push);
    });
  });

  describe('CLOSE_ISSUE', () => {
    it('should set issue as closed', () => {
      store.$patch({
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      });

      store[types.CLOSE_ISSUE]();

      expect(store.noteableData.state).toEqual('closed');
    });
  });

  describe('REOPEN_ISSUE', () => {
    it('should set issue as closed', () => {
      store.$patch({
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      });

      store[types.REOPEN_ISSUE]();

      expect(store.noteableData.state).toEqual('reopened');
    });
  });

  describe('TOGGLE_STATE_BUTTON_LOADING', () => {
    it('should set isToggleStateButtonLoading as true', () => {
      store.$patch({
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      });

      store[types.TOGGLE_STATE_BUTTON_LOADING](true);

      expect(store.isToggleStateButtonLoading).toEqual(true);
    });

    it('should set isToggleStateButtonLoading as false', () => {
      store.$patch({
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: true,
        notesData: {},
        userData: {},
        noteableData: {},
      });

      store[types.TOGGLE_STATE_BUTTON_LOADING](false);

      expect(store.isToggleStateButtonLoading).toEqual(false);
    });
  });

  describe('SET_NOTES_FETCHED_STATE', () => {
    it('should set the given state', () => {
      store.$patch({
        isNotesFetched: false,
      });

      store[types.SET_NOTES_FETCHED_STATE](true);

      expect(store.isNotesFetched).toEqual(true);
    });
  });

  describe('SET_DISCUSSION_DIFF_LINES', () => {
    it('sets truncated_diff_lines', () => {
      store.$patch({
        discussions: [
          {
            id: 1,
          },
        ],
      });

      store[types.SET_DISCUSSION_DIFF_LINES]({
        discussionId: 1,
        diffLines: [{ text: '+a', rich_text: '+<span>a</span>' }],
      });

      expect(store.discussions[0].truncated_diff_lines).toEqual([{ rich_text: '<span>a</span>' }]);
    });

    it('keeps reactivity of discussion', () => {
      store.$patch({
        discussions: [
          {
            id: 1,
            expanded: false,
          },
        ],
      });

      const discussion = store.discussions[0];

      store[types.SET_DISCUSSION_DIFF_LINES]({
        discussionId: 1,
        diffLines: [{ rich_text: '<span>a</span>' }],
      });

      discussion.expanded = true;

      expect(store.discussions[0].expanded).toBe(true);
    });
  });

  describe('SET_SELECTED_COMMENT_POSITION', () => {
    it('should set comment position state', () => {
      store[types.SET_SELECTED_COMMENT_POSITION]({});

      expect(store.selectedCommentPosition).toEqual({});
    });
  });

  describe('SET_SELECTED_COMMENT_POSITION_HOVER', () => {
    it('should set comment hover position state', () => {
      store[types.SET_SELECTED_COMMENT_POSITION_HOVER]({});

      expect(store.selectedCommentPositionHover).toEqual({});
    });
  });

  describe('DISABLE_COMMENTS', () => {
    it('should set comments disabled state', () => {
      store[types.DISABLE_COMMENTS](true);

      expect(store.commentsDisabled).toEqual(true);
    });
  });

  describe('UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS', () => {
    it('with unresolvable discussions, updates state', () => {
      store.$patch({
        discussions: [
          { individual_note: false, resolvable: true, notes: [UNRESOLVED_NOTE] },
          { individual_note: true, resolvable: true, notes: [UNRESOLVED_NOTE] },
          { individual_note: false, resolvable: false, notes: [UNRESOLVED_NOTE] },
        ],
      });

      store[types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS]();

      expect(store).toEqual(
        expect.objectContaining({
          resolvableDiscussionsCount: 1,
          unresolvedDiscussionsCount: 1,
        }),
      );
    });

    it('with resolvable discussions, updates state', () => {
      store.$patch({
        discussions: [
          {
            individual_note: false,
            resolvable: true,
            notes: [RESOLVED_NOTE, SYSTEM_NOTE, RESOLVED_NOTE],
          },
          {
            individual_note: false,
            resolvable: true,
            notes: [RESOLVED_NOTE, SYSTEM_NOTE, WEIRD_NOTE],
          },
          {
            individual_note: false,
            resolvable: true,
            notes: [SYSTEM_NOTE, RESOLVED_NOTE, WEIRD_NOTE, UNRESOLVED_NOTE],
          },
          {
            individual_note: false,
            resolvable: true,
            notes: [UNRESOLVED_NOTE],
          },
        ],
      });

      store[types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS]();

      expect(store).toEqual(
        expect.objectContaining({
          resolvableDiscussionsCount: 4,
          unresolvedDiscussionsCount: 2,
        }),
      );
    });
  });

  describe('CONVERT_TO_DISCUSSION', () => {
    let discussion;

    beforeEach(() => {
      discussion = {
        id: 42,
        individual_note: true,
      };
    });

    it('adds a discussion to convertedDisscussionIds', () => {
      store[types.CONVERT_TO_DISCUSSION](discussion.id);

      expect(store.convertedDisscussionIds).toContain(discussion.id);
    });
  });

  describe('REMOVE_CONVERTED_DISCUSSION', () => {
    let discussion;

    beforeEach(() => {
      discussion = {
        id: 42,
        individual_note: true,
      };
      store.$patch({ convertedDisscussionIds: [41, 42] });
    });

    it('removes a discussion from convertedDisscussionIds', () => {
      store[types.REMOVE_CONVERTED_DISCUSSION](discussion.id);

      expect(store.convertedDisscussionIds).not.toContain(discussion.id);
    });
  });

  describe('RECEIVE_DESCRIPTION_VERSION', () => {
    const descriptionVersion = notesWithDescriptionChanges[0].notes[0].note;
    const versionId = notesWithDescriptionChanges[0].notes[0].id;

    it('adds a descriptionVersion', () => {
      store[types.RECEIVE_DESCRIPTION_VERSION]({ descriptionVersion, versionId });
      expect(store.descriptionVersions[versionId]).toBe(descriptionVersion);
    });
  });

  describe('RECEIVE_DELETE_DESCRIPTION_VERSION', () => {
    const descriptionVersion = notesWithDescriptionChanges[0].notes[0].note;
    const versionId = notesWithDescriptionChanges[0].notes[0].id;
    const deleted = 'Deleted';

    beforeEach(() => {
      store.$patch({ descriptionVersions: { [versionId]: descriptionVersion } });
    });

    it('updates descriptionVersion to "Deleted"', () => {
      store[types.RECEIVE_DELETE_DESCRIPTION_VERSION]({ [versionId]: deleted });
      expect(store.descriptionVersions[versionId]).toBe(deleted);
    });
  });

  describe('SET_DISCUSSIONS_SORT', () => {
    it('sets sort order', () => {
      store[types.SET_DISCUSSIONS_SORT]({ direction: DESC, persist: false });

      expect(store.discussionSortOrder).toBe(DESC);
      expect(store.persistSortOrder).toBe(false);
    });
  });

  describe('SET_APPLYING_BATCH_STATE', () => {
    const buildDiscussions = (suggestionsInfo) => {
      const suggestions = suggestionsInfo.map(({ suggestionId }) => ({ id: suggestionId }));

      const notes = suggestionsInfo.map(({ noteId }, index) => ({
        id: noteId,
        suggestions: [suggestions[index]],
      }));

      return suggestionsInfo.map(({ discussionId }, index) => ({
        id: discussionId,
        notes: [notes[index]],
      }));
    };

    let batchedSuggestionInfo;
    let discussions;
    let suggestions;

    beforeEach(() => {
      [batchedSuggestionInfo] = batchSuggestionsInfoMock;
      suggestions = batchSuggestionsInfoMock.map(({ suggestionId }) => ({ id: suggestionId }));
      discussions = buildDiscussions(batchSuggestionsInfoMock);
      store.$patch({
        batchSuggestionsInfo: [batchedSuggestionInfo],
        discussions,
      });
    });

    it('sets is_applying_batch to a boolean value for all batched suggestions', () => {
      store[types.SET_APPLYING_BATCH_STATE](true);

      const updatedSuggestion = {
        ...suggestions[0],
        is_applying_batch: true,
      };

      const expectedSuggestions = [updatedSuggestion, suggestions[1]];

      const actualSuggestions = store.discussions
        .map((discussion) => discussion.notes.map((n) => n.suggestions))
        .flat(2);

      expect(actualSuggestions).toEqual(expectedSuggestions);
    });
  });

  describe('ADD_SUGGESTION_TO_BATCH', () => {
    it("adds a suggestion's info to a batch", () => {
      const suggestionInfo = {
        suggestionId: 'a123',
        noteId: 'b456',
        discussionId: 'c789',
      };

      store[types.ADD_SUGGESTION_TO_BATCH](suggestionInfo);

      expect(store.batchSuggestionsInfo).toEqual([suggestionInfo]);
    });
  });

  describe('REMOVE_SUGGESTION_FROM_BATCH', () => {
    let suggestionInfo1;
    let suggestionInfo2;

    beforeEach(() => {
      [suggestionInfo1, suggestionInfo2] = batchSuggestionsInfoMock;

      store.$patch({
        batchSuggestionsInfo: [suggestionInfo1, suggestionInfo2],
      });
    });

    it("removes a suggestion's info from a batch", () => {
      store[types.REMOVE_SUGGESTION_FROM_BATCH](suggestionInfo1.suggestionId);

      expect(store.batchSuggestionsInfo).toEqual([suggestionInfo2]);
    });
  });

  describe('CLEAR_SUGGESTION_BATCH', () => {
    beforeEach(() => {
      store.$patch({
        batchSuggestionsInfo: batchSuggestionsInfoMock,
      });
    });

    it('removes info for all suggestions from a batch', () => {
      store[types.CLEAR_SUGGESTION_BATCH]();

      expect(store.batchSuggestionsInfo.length).toEqual(0);
    });
  });

  describe('SET_ISSUE_CONFIDENTIAL', () => {
    beforeEach(() => {
      store.$patch({ noteableData: { confidential: false } });
    });

    it('should set issuable as confidential', () => {
      store[types.SET_ISSUE_CONFIDENTIAL](true);

      expect(store.noteableData.confidential).toBe(true);
    });
  });

  describe('SET_ISSUABLE_LOCK', () => {
    beforeEach(() => {
      store.$patch({ noteableData: { discussion_locked: false } });
    });

    it('should set issuable as locked', () => {
      store[types.SET_ISSUABLE_LOCK](true);

      expect(store.noteableData.discussion_locked).toBe(true);
    });
  });

  describe('UPDATE_ASSIGNEES', () => {
    it('should update assignees', () => {
      store.$patch({
        noteableData: noteableDataMock,
      });

      store[types.UPDATE_ASSIGNEES]([userDataMock.id]);

      expect(store.noteableData.assignees).toEqual([userDataMock.id]);
    });
  });

  describe('UPDATE_DISCUSSION_POSITION', () => {
    it('should upate the discusion position', () => {
      const discussion1 = { id: 1, position: { line_code: 'abc_1_1' } };
      const discussion2 = { id: 2, position: { line_code: 'abc_2_2' } };
      const discussion3 = { id: 3, position: { line_code: 'abc_3_3' } };
      store.$patch({
        discussions: [discussion1, discussion2, discussion3],
      });
      const discussion1Position = { ...discussion1.position };
      const position = { ...discussion1Position, test: true };

      store[types.UPDATE_DISCUSSION_POSITION]({ discussionId: discussion1.id, position });
      expect(store.discussions[0].position).toEqual(position);
    });
  });

  describe('SET_DONE_FETCHING_BATCH_DISCUSSIONS', () => {
    it('should set doneFetchingBatchDiscussions', () => {
      store.$patch({
        doneFetchingBatchDiscussions: false,
      });

      store[types.SET_DONE_FETCHING_BATCH_DISCUSSIONS](true);

      expect(store.doneFetchingBatchDiscussions).toEqual(true);
    });
  });

  describe('SET_EXPAND_ALL_DISCUSSIONS', () => {
    it('should set expanded for every discussion', () => {
      store.$patch({
        discussions: [{ expanded: false }, { expanded: false }],
      });

      store[types.SET_EXPAND_ALL_DISCUSSIONS](true);

      expect(store.discussions).toStrictEqual([{ expanded: true }, { expanded: true }]);
    });
  });
});
