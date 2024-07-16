import { DISCUSSION_NOTE, ASC, DESC } from '~/notes/constants';
import mutations from '~/notes/stores/mutations';
import {
  note,
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  notesWithDescriptionChanges,
  batchSuggestionsInfoMock,
} from '../mock_data';

const RESOLVED_NOTE = { resolvable: true, resolved: true };
const UNRESOLVED_NOTE = { resolvable: true, resolved: false };
const SYSTEM_NOTE = { resolvable: false, resolved: false };
const WEIRD_NOTE = { resolvable: false, resolved: true };

describe('Notes Store mutations', () => {
  describe('ADD_NEW_NOTE', () => {
    let state;
    let noteData;

    beforeEach(() => {
      state = {
        discussions: [],
        discussionSortOrder: ASC,
      };
      noteData = {
        expanded: true,
        id: note.discussion_id,
        individual_note: true,
        notes: [note],
        reply_id: note.discussion_id,
      };
    });

    it('should add a new note to an array of notes', () => {
      mutations.ADD_NEW_NOTE(state, note);
      expect(state).toEqual(expect.objectContaining({ discussions: [noteData] }));

      expect(state.discussions.length).toBe(1);
    });

    it('should not add the same note to the notes array', () => {
      mutations.ADD_NEW_NOTE(state, note);
      mutations.ADD_NEW_NOTE(state, note);

      expect(state.discussions.length).toBe(1);
    });

    it('trims first character from truncated_diff_lines', () => {
      mutations.ADD_NEW_NOTE(state, {
        discussion: {
          notes: [{ ...note }],
          truncated_diff_lines: [{ text: '+a', rich_text: '+<span>a</span>' }],
        },
      });

      expect(state.discussions[0].truncated_diff_lines).toEqual([{ rich_text: '<span>a</span>' }]);
    });
  });

  describe('ADD_NEW_REPLY_TO_DISCUSSION', () => {
    const newReply = { ...note, discussion_id: discussionMock.id };

    let state;

    beforeEach(() => {
      state = { discussions: [{ ...discussionMock }] };
    });

    it('should add a reply to a specific discussion', () => {
      mutations.ADD_NEW_REPLY_TO_DISCUSSION(state, newReply);

      expect(state.discussions[0].notes.length).toEqual(4);
    });

    it('should not add the note if it already exists in the discussion', () => {
      mutations.ADD_NEW_REPLY_TO_DISCUSSION(state, newReply);
      mutations.ADD_NEW_REPLY_TO_DISCUSSION(state, newReply);

      expect(state.discussions[0].notes.length).toEqual(4);
    });
  });

  describe('DELETE_NOTE', () => {
    it('should delete a note', () => {
      const state = { discussions: [discussionMock] };
      const toDelete = discussionMock.notes[0];
      const lengthBefore = discussionMock.notes.length;

      mutations.DELETE_NOTE(state, toDelete);

      expect(state.discussions[0].notes.length).toEqual(lengthBefore - 1);
    });
  });

  describe('EXPAND_DISCUSSION', () => {
    it('should expand a collapsed discussion', () => {
      const discussion = { ...discussionMock, expanded: false };

      const state = {
        discussions: [discussion],
      };

      mutations.EXPAND_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(true);
    });
  });

  describe('COLLAPSE_DISCUSSION', () => {
    it('should collapse an expanded discussion', () => {
      const discussion = { ...discussionMock, expanded: true };

      const state = {
        discussions: [discussion],
      };

      mutations.COLLAPSE_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(false);
    });
  });

  describe('REMOVE_PLACEHOLDER_NOTES', () => {
    it('should remove all placeholder individual notes', () => {
      const placeholderNote = { ...individualNote, isPlaceholderNote: true };
      const state = { discussions: [placeholderNote] };

      mutations.REMOVE_PLACEHOLDER_NOTES(state);

      expect(state.discussions).toEqual([]);
    });

    it.each`
      discussionType | discussion
      ${'initial'}   | ${individualNote}
      ${'continued'} | ${discussionMock}
    `('should remove all placeholder notes from $discussionType discussions', ({ discussion }) => {
      const lengthBefore = discussion.notes.length;

      const placeholderNote = { ...individualNote, isPlaceholderNote: true };
      discussion.notes.push(placeholderNote);

      const state = {
        discussions: [discussion],
      };

      mutations.REMOVE_PLACEHOLDER_NOTES(state);

      expect(state.discussions[0].notes.length).toEqual(lengthBefore);
    });
  });

  describe('SET_NOTES_DATA', () => {
    it('should set an object with notesData', () => {
      const state = {
        notesData: {},
      };

      mutations.SET_NOTES_DATA(state, notesDataMock);

      expect(state.notesData).toEqual(notesDataMock);
    });
  });

  describe('SET_NOTEABLE_DATA', () => {
    it('should set the issue data', () => {
      const state = {
        noteableData: {},
      };

      mutations.SET_NOTEABLE_DATA(state, noteableDataMock);

      expect(state.noteableData).toEqual(noteableDataMock);
    });
  });

  describe('SET_USER_DATA', () => {
    it('should set the user data', () => {
      const state = {
        userData: {},
      };

      mutations.SET_USER_DATA(state, userDataMock);

      expect(state.userData).toEqual(userDataMock);
    });
  });

  describe('CLEAR_DISCUSSIONS', () => {
    it('should set discussions to an empty array', () => {
      const state = {
        discussions: [discussionMock],
      };

      mutations.CLEAR_DISCUSSIONS(state);

      expect(state.discussions).toEqual([]);
    });
  });

  describe('ADD_OR_UPDATE_DISCUSSIONS', () => {
    it('should set the initial notes received', () => {
      const state = {
        discussions: [],
      };
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

      mutations.ADD_OR_UPDATE_DISCUSSIONS(state, [note, legacyNote]);

      expect(state.discussions[0].id).toEqual(note.id);
      expect(state.discussions[1].notes[0].note).toBe(legacyNote.notes[0].note);
      expect(state.discussions[2].notes[0].note).toBe(legacyNote.notes[1].note);
      expect(state.discussions.length).toEqual(3);
    });

    it('adds truncated_diff_lines if discussion is a diffFile', () => {
      const state = {
        discussions: [],
      };

      mutations.ADD_OR_UPDATE_DISCUSSIONS(state, [
        {
          ...note,
          diff_file: {
            file_hash: 'a',
          },
          truncated_diff_lines: [{ text: '+a', rich_text: '+<span>a</span>' }],
        },
      ]);

      expect(state.discussions[0].truncated_diff_lines).toEqual([{ rich_text: '<span>a</span>' }]);
    });

    it('adds empty truncated_diff_lines when not in discussion', () => {
      const state = {
        discussions: [],
      };

      mutations.ADD_OR_UPDATE_DISCUSSIONS(state, [
        {
          ...note,
          diff_file: {
            file_hash: 'a',
          },
        },
      ]);

      expect(state.discussions[0].truncated_diff_lines).toEqual([]);
    });
  });

  describe('SET_LAST_FETCHED_AT', () => {
    it('should set timestamp', () => {
      const state = {
        lastFetchedAt: [],
      };

      mutations.SET_LAST_FETCHED_AT(state, 'timestamp');

      expect(state.lastFetchedAt).toEqual('timestamp');
    });
  });

  describe('SET_TARGET_NOTE_HASH', () => {
    it('should set the note hash', () => {
      const state = {
        targetNoteHash: [],
      };

      mutations.SET_TARGET_NOTE_HASH(state, 'hash');

      expect(state.targetNoteHash).toEqual('hash');
    });
  });

  describe('SHOW_PLACEHOLDER_NOTE', () => {
    it('should set a placeholder note', () => {
      const state = {
        discussions: [],
      };
      mutations.SHOW_PLACEHOLDER_NOTE(state, note);

      expect(state.discussions[0].isPlaceholderNote).toEqual(true);
    });
  });

  describe('TOGGLE_AWARD', () => {
    it('should add award if user has not reacted yet', () => {
      const state = {
        discussions: [note],
        userData: userDataMock,
      };

      const data = {
        note,
        awardName: 'cartwheel',
      };

      mutations.TOGGLE_AWARD(state, data);
      const lastIndex = state.discussions[0].award_emoji.length - 1;

      expect(state.discussions[0].award_emoji[lastIndex]).toEqual({
        name: 'cartwheel',
        user: { id: userDataMock.id, name: userDataMock.name, username: userDataMock.username },
      });
    });

    it('should remove award if user already reacted', () => {
      const state = {
        discussions: [note],
        userData: {
          id: 1,
          name: 'Administrator',
          username: 'root',
        },
      };

      const data = {
        note,
        awardName: 'bath_tone3',
      };
      mutations.TOGGLE_AWARD(state, data);

      expect(state.discussions[0].award_emoji.length).toEqual(2);
    });
  });

  describe('TOGGLE_DISCUSSION', () => {
    it('should open a closed discussion', () => {
      const discussion = { ...discussionMock, expanded: false };

      const state = {
        discussions: [discussion],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(true);
    });

    it('should close a opened discussion', () => {
      const state = {
        discussions: [discussionMock],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussionMock.id });

      expect(state.discussions[0].expanded).toEqual(false);
    });

    it('forces a discussions expanded state', () => {
      const state = {
        discussions: [{ ...discussionMock, expanded: false }],
      };

      mutations.TOGGLE_DISCUSSION(state, { discussionId: discussionMock.id, forceExpanded: true });

      expect(state.discussions[0].expanded).toEqual(true);
    });
  });

  describe('SET_EXPAND_DISCUSSIONS', () => {
    it('should succeed when discussions are null', () => {
      const state = {};

      mutations.SET_EXPAND_DISCUSSIONS(state, { discussionIds: null, expanded: true });

      expect(state).toEqual({});
    });

    it('should succeed when discussions are empty', () => {
      const state = {};

      mutations.SET_EXPAND_DISCUSSIONS(state, { discussionIds: [], expanded: true });

      expect(state).toEqual({});
    });

    it('should open all closed discussions', () => {
      const discussion1 = { ...discussionMock, id: 0, expanded: false };
      const discussion2 = { ...discussionMock, id: 1, expanded: true };
      const discussionIds = [discussion1.id, discussion2.id];

      const state = { discussions: [discussion1, discussion2] };

      mutations.SET_EXPAND_DISCUSSIONS(state, { discussionIds, expanded: true });

      state.discussions.forEach((discussion) => {
        expect(discussion.expanded).toEqual(true);
      });
    });

    it('should close all opened discussions', () => {
      const discussion1 = { ...discussionMock, id: 0, expanded: false };
      const discussion2 = { ...discussionMock, id: 1, expanded: true };
      const discussionIds = [discussion1.id, discussion2.id];

      const state = { discussions: [discussion1, discussion2] };

      mutations.SET_EXPAND_DISCUSSIONS(state, { discussionIds, expanded: false });

      state.discussions.forEach((discussion) => {
        expect(discussion.expanded).toEqual(false);
      });
    });
  });

  describe('SET_RESOLVING_DISCUSSION', () => {
    it('should set resolving discussion state', () => {
      const state = {};

      mutations.SET_RESOLVING_DISCUSSION(state, true);

      expect(state.isResolvingDiscussion).toEqual(true);
    });
  });

  describe('UPDATE_NOTE', () => {
    it('should update a note', () => {
      const state = {
        discussions: [individualNote],
      };

      const updated = { ...individualNote.notes[0], note: 'Foo' };

      mutations.UPDATE_NOTE(state, updated);

      expect(state.discussions[0].notes[0].note).toEqual('Foo');
    });

    it('does not update existing note if it matches', () => {
      const state = {
        discussions: [{ ...individualNote, individual_note: false }],
      };
      jest.spyOn(state.discussions[0].notes, 'splice');

      const updated = individualNote.notes[0];

      mutations.UPDATE_NOTE(state, updated);

      expect(state.discussions[0].notes.splice).not.toHaveBeenCalled();
    });

    it('transforms an individual note to discussion', () => {
      const state = {
        discussions: [individualNote],
      };

      const transformedNote = {
        ...individualNote.notes[0],
        type: DISCUSSION_NOTE,
        resolvable: true,
      };

      mutations.UPDATE_NOTE(state, transformedNote);

      expect(state.discussions[0].individual_note).toEqual(false);
      expect(state.discussions[0].resolvable).toEqual(true);
    });

    it('copies resolve state to discussion', () => {
      const state = { discussions: [{ ...discussionMock }] };

      const resolvedNote = {
        ...discussionMock.notes[0],
        resolvable: true,
        resolved: true,
        resolved_at: '2017-08-02T10:51:58.559Z',
        resolved_by: discussionMock.notes[0].author,
        resolved_by_push: false,
      };

      mutations.UPDATE_NOTE(state, resolvedNote);

      expect(state.discussions[0].resolved).toEqual(resolvedNote.resolved);
      expect(state.discussions[0].resolved_at).toEqual(resolvedNote.resolved_at);
      expect(state.discussions[0].resolved_by).toEqual(resolvedNote.resolved_by);
      expect(state.discussions[0].resolved_by_push).toEqual(resolvedNote.resolved_by_push);
    });
  });

  describe('CLOSE_ISSUE', () => {
    it('should set issue as closed', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.CLOSE_ISSUE(state);

      expect(state.noteableData.state).toEqual('closed');
    });
  });

  describe('REOPEN_ISSUE', () => {
    it('should set issue as closed', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.REOPEN_ISSUE(state);

      expect(state.noteableData.state).toEqual('reopened');
    });
  });

  describe('TOGGLE_STATE_BUTTON_LOADING', () => {
    it('should set isToggleStateButtonLoading as true', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: false,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.TOGGLE_STATE_BUTTON_LOADING(state, true);

      expect(state.isToggleStateButtonLoading).toEqual(true);
    });

    it('should set isToggleStateButtonLoading as false', () => {
      const state = {
        discussions: [],
        targetNoteHash: null,
        lastFetchedAt: null,
        isToggleStateButtonLoading: true,
        notesData: {},
        userData: {},
        noteableData: {},
      };

      mutations.TOGGLE_STATE_BUTTON_LOADING(state, false);

      expect(state.isToggleStateButtonLoading).toEqual(false);
    });
  });

  describe('SET_NOTES_FETCHED_STATE', () => {
    it('should set the given state', () => {
      const state = {
        isNotesFetched: false,
      };

      mutations.SET_NOTES_FETCHED_STATE(state, true);

      expect(state.isNotesFetched).toEqual(true);
    });
  });

  describe('SET_DISCUSSION_DIFF_LINES', () => {
    it('sets truncated_diff_lines', () => {
      const state = {
        discussions: [
          {
            id: 1,
          },
        ],
      };

      mutations.SET_DISCUSSION_DIFF_LINES(state, {
        discussionId: 1,
        diffLines: [{ text: '+a', rich_text: '+<span>a</span>' }],
      });

      expect(state.discussions[0].truncated_diff_lines).toEqual([{ rich_text: '<span>a</span>' }]);
    });

    it('keeps reactivity of discussion', () => {
      const state = {
        discussions: [
          {
            id: 1,
            expanded: false,
          },
        ],
      };

      const discussion = state.discussions[0];

      mutations.SET_DISCUSSION_DIFF_LINES(state, {
        discussionId: 1,
        diffLines: [{ rich_text: '<span>a</span>' }],
      });

      discussion.expanded = true;

      expect(state.discussions[0].expanded).toBe(true);
    });
  });

  describe('SET_SELECTED_COMMENT_POSITION', () => {
    it('should set comment position state', () => {
      const state = {};

      mutations.SET_SELECTED_COMMENT_POSITION(state, {});

      expect(state.selectedCommentPosition).toEqual({});
    });
  });

  describe('SET_SELECTED_COMMENT_POSITION_HOVER', () => {
    it('should set comment hover position state', () => {
      const state = {};

      mutations.SET_SELECTED_COMMENT_POSITION_HOVER(state, {});

      expect(state.selectedCommentPositionHover).toEqual({});
    });
  });

  describe('DISABLE_COMMENTS', () => {
    it('should set comments disabled state', () => {
      const state = {};

      mutations.DISABLE_COMMENTS(state, true);

      expect(state.commentsDisabled).toEqual(true);
    });
  });

  describe('UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS', () => {
    it('with unresolvable discussions, updates state', () => {
      const state = {
        discussions: [
          { individual_note: false, resolvable: true, notes: [UNRESOLVED_NOTE] },
          { individual_note: true, resolvable: true, notes: [UNRESOLVED_NOTE] },
          { individual_note: false, resolvable: false, notes: [UNRESOLVED_NOTE] },
        ],
      };

      mutations.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS(state);

      expect(state).toEqual(
        expect.objectContaining({
          resolvableDiscussionsCount: 1,
          unresolvedDiscussionsCount: 1,
        }),
      );
    });

    it('with resolvable discussions, updates state', () => {
      const state = {
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
      };

      mutations.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS(state);

      expect(state).toEqual(
        expect.objectContaining({
          resolvableDiscussionsCount: 4,
          unresolvedDiscussionsCount: 2,
        }),
      );
    });
  });

  describe('CONVERT_TO_DISCUSSION', () => {
    let discussion;
    let state;

    beforeEach(() => {
      discussion = {
        id: 42,
        individual_note: true,
      };
      state = { convertedDisscussionIds: [] };
    });

    it('adds a discussion to convertedDisscussionIds', () => {
      mutations.CONVERT_TO_DISCUSSION(state, discussion.id);

      expect(state.convertedDisscussionIds).toContain(discussion.id);
    });
  });

  describe('REMOVE_CONVERTED_DISCUSSION', () => {
    let discussion;
    let state;

    beforeEach(() => {
      discussion = {
        id: 42,
        individual_note: true,
      };
      state = { convertedDisscussionIds: [41, 42] };
    });

    it('removes a discussion from convertedDisscussionIds', () => {
      mutations.REMOVE_CONVERTED_DISCUSSION(state, discussion.id);

      expect(state.convertedDisscussionIds).not.toContain(discussion.id);
    });
  });

  describe('RECEIVE_DESCRIPTION_VERSION', () => {
    const descriptionVersion = notesWithDescriptionChanges[0].notes[0].note;
    const versionId = notesWithDescriptionChanges[0].notes[0].id;
    const state = {};

    it('adds a descriptionVersion', () => {
      mutations.RECEIVE_DESCRIPTION_VERSION(state, { descriptionVersion, versionId });
      expect(state.descriptionVersions[versionId]).toBe(descriptionVersion);
    });
  });

  describe('RECEIVE_DELETE_DESCRIPTION_VERSION', () => {
    const descriptionVersion = notesWithDescriptionChanges[0].notes[0].note;
    const versionId = notesWithDescriptionChanges[0].notes[0].id;
    const state = { descriptionVersions: { [versionId]: descriptionVersion } };
    const deleted = 'Deleted';

    it('updates descriptionVersion to "Deleted"', () => {
      mutations.RECEIVE_DELETE_DESCRIPTION_VERSION(state, { [versionId]: deleted });
      expect(state.descriptionVersions[versionId]).toBe(deleted);
    });
  });

  describe('SET_DISCUSSIONS_SORT', () => {
    let state;

    beforeEach(() => {
      state = { discussionSortOrder: ASC };
    });

    it('sets sort order', () => {
      mutations.SET_DISCUSSIONS_SORT(state, { direction: DESC, persist: false });

      expect(state.discussionSortOrder).toBe(DESC);
      expect(state.persistSortOrder).toBe(false);
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

    let state;
    let batchedSuggestionInfo;
    let discussions;
    let suggestions;

    beforeEach(() => {
      [batchedSuggestionInfo] = batchSuggestionsInfoMock;
      suggestions = batchSuggestionsInfoMock.map(({ suggestionId }) => ({ id: suggestionId }));
      discussions = buildDiscussions(batchSuggestionsInfoMock);
      state = {
        batchSuggestionsInfo: [batchedSuggestionInfo],
        discussions,
      };
    });

    it('sets is_applying_batch to a boolean value for all batched suggestions', () => {
      mutations.SET_APPLYING_BATCH_STATE(state, true);

      const updatedSuggestion = {
        ...suggestions[0],
        is_applying_batch: true,
      };

      const expectedSuggestions = [updatedSuggestion, suggestions[1]];

      const actualSuggestions = state.discussions
        .map((discussion) => discussion.notes.map((n) => n.suggestions))
        .flat(2);

      expect(actualSuggestions).toEqual(expectedSuggestions);
    });
  });

  describe('ADD_SUGGESTION_TO_BATCH', () => {
    let state;

    beforeEach(() => {
      state = { batchSuggestionsInfo: [] };
    });

    it("adds a suggestion's info to a batch", () => {
      const suggestionInfo = {
        suggestionId: 'a123',
        noteId: 'b456',
        discussionId: 'c789',
      };

      mutations.ADD_SUGGESTION_TO_BATCH(state, suggestionInfo);

      expect(state.batchSuggestionsInfo).toEqual([suggestionInfo]);
    });
  });

  describe('REMOVE_SUGGESTION_FROM_BATCH', () => {
    let state;
    let suggestionInfo1;
    let suggestionInfo2;

    beforeEach(() => {
      [suggestionInfo1, suggestionInfo2] = batchSuggestionsInfoMock;

      state = {
        batchSuggestionsInfo: [suggestionInfo1, suggestionInfo2],
      };
    });

    it("removes a suggestion's info from a batch", () => {
      mutations.REMOVE_SUGGESTION_FROM_BATCH(state, suggestionInfo1.suggestionId);

      expect(state.batchSuggestionsInfo).toEqual([suggestionInfo2]);
    });
  });

  describe('CLEAR_SUGGESTION_BATCH', () => {
    let state;

    beforeEach(() => {
      state = {
        batchSuggestionsInfo: batchSuggestionsInfoMock,
      };
    });

    it('removes info for all suggestions from a batch', () => {
      mutations.CLEAR_SUGGESTION_BATCH(state);

      expect(state.batchSuggestionsInfo.length).toEqual(0);
    });
  });

  describe('SET_ISSUE_CONFIDENTIAL', () => {
    let state;

    beforeEach(() => {
      state = { noteableData: { confidential: false } };
    });

    it('should set issuable as confidential', () => {
      mutations.SET_ISSUE_CONFIDENTIAL(state, true);

      expect(state.noteableData.confidential).toBe(true);
    });
  });

  describe('SET_ISSUABLE_LOCK', () => {
    let state;

    beforeEach(() => {
      state = { noteableData: { discussion_locked: false } };
    });

    it('should set issuable as locked', () => {
      mutations.SET_ISSUABLE_LOCK(state, true);

      expect(state.noteableData.discussion_locked).toBe(true);
    });
  });

  describe('UPDATE_ASSIGNEES', () => {
    it('should update assignees', () => {
      const state = {
        noteableData: noteableDataMock,
      };

      mutations.UPDATE_ASSIGNEES(state, [userDataMock.id]);

      expect(state.noteableData.assignees).toEqual([userDataMock.id]);
    });
  });

  describe('UPDATE_DISCUSSION_POSITION', () => {
    it('should upate the discusion position', () => {
      const discussion1 = { id: 1, position: { line_code: 'abc_1_1' } };
      const discussion2 = { id: 2, position: { line_code: 'abc_2_2' } };
      const discussion3 = { id: 3, position: { line_code: 'abc_3_3' } };
      const state = {
        discussions: [discussion1, discussion2, discussion3],
      };
      const discussion1Position = { ...discussion1.position };
      const position = { ...discussion1Position, test: true };

      mutations.UPDATE_DISCUSSION_POSITION(state, { discussionId: discussion1.id, position });
      expect(state.discussions[0].position).toEqual(position);
    });
  });

  describe('SET_DONE_FETCHING_BATCH_DISCUSSIONS', () => {
    it('should set doneFetchingBatchDiscussions', () => {
      const state = {
        doneFetchingBatchDiscussions: false,
      };

      mutations.SET_DONE_FETCHING_BATCH_DISCUSSIONS(state, true);

      expect(state.doneFetchingBatchDiscussions).toEqual(true);
    });
  });

  describe('SET_EXPAND_ALL_DISCUSSIONS', () => {
    it('should set expanded for every discussion', () => {
      const state = {
        discussions: [{ expanded: false }, { expanded: false }],
      };

      mutations.SET_EXPAND_ALL_DISCUSSIONS(state, true);

      expect(state.discussions).toStrictEqual([{ expanded: true }, { expanded: true }]);
    });
  });
});
