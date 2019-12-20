import Vue from 'vue';
import mutations from '~/notes/stores/mutations';
import { DISCUSSION_NOTE } from '~/notes/constants';
import {
  note,
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
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
      state = { discussions: [] };
      noteData = {
        expanded: true,
        id: note.discussion_id,
        individual_note: true,
        notes: [note],
        reply_id: note.discussion_id,
      };
      mutations.ADD_NEW_NOTE(state, note);
    });

    it('should add a new note to an array of notes', () => {
      expect(state).toEqual({
        discussions: [noteData],
      });

      expect(state.discussions.length).toBe(1);
    });

    it('should not add the same note to the notes array', () => {
      mutations.ADD_NEW_NOTE(state, note);

      expect(state.discussions.length).toBe(1);
    });
  });

  describe('ADD_NEW_REPLY_TO_DISCUSSION', () => {
    const newReply = Object.assign({}, note, { discussion_id: discussionMock.id });

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
    it('should delete a note ', () => {
      const state = { discussions: [discussionMock] };
      const toDelete = discussionMock.notes[0];
      const lengthBefore = discussionMock.notes.length;

      mutations.DELETE_NOTE(state, toDelete);

      expect(state.discussions[0].notes.length).toEqual(lengthBefore - 1);
    });
  });

  describe('EXPAND_DISCUSSION', () => {
    it('should expand a collapsed discussion', () => {
      const discussion = Object.assign({}, discussionMock, { expanded: false });

      const state = {
        discussions: [discussion],
      };

      mutations.EXPAND_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(true);
    });
  });

  describe('COLLAPSE_DISCUSSION', () => {
    it('should collapse an expanded discussion', () => {
      const discussion = Object.assign({}, discussionMock, { expanded: true });

      const state = {
        discussions: [discussion],
      };

      mutations.COLLAPSE_DISCUSSION(state, { discussionId: discussion.id });

      expect(state.discussions[0].expanded).toEqual(false);
    });
  });

  describe('REMOVE_PLACEHOLDER_NOTES', () => {
    it('should remove all placeholder notes in indivudal notes and discussion', () => {
      const placeholderNote = Object.assign({}, individualNote, { isPlaceholderNote: true });
      const state = { discussions: [placeholderNote] };
      mutations.REMOVE_PLACEHOLDER_NOTES(state);

      expect(state.discussions).toEqual([]);
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

  describe('SET_INITIAL_DISCUSSIONS', () => {
    it('should set the initial notes received', () => {
      const state = {
        discussions: [],
      };
      const legacyNote = {
        id: 2,
        individual_note: true,
        notes: [
          {
            note: '1',
          },
          {
            note: '2',
          },
        ],
      };

      mutations.SET_INITIAL_DISCUSSIONS(state, [note, legacyNote]);

      expect(state.discussions[0].id).toEqual(note.id);
      expect(state.discussions[1].notes[0].note).toBe(legacyNote.notes[0].note);
      expect(state.discussions[2].notes[0].note).toBe(legacyNote.notes[1].note);
      expect(state.discussions.length).toEqual(3);
    });

    it('adds truncated_diff_lines if discussion is a diffFile', () => {
      const state = {
        discussions: [],
      };

      mutations.SET_INITIAL_DISCUSSIONS(state, [
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

      mutations.SET_INITIAL_DISCUSSIONS(state, [
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
      const discussion = Object.assign({}, discussionMock, { expanded: false });

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

  describe('UPDATE_NOTE', () => {
    it('should update a note', () => {
      const state = {
        discussions: [individualNote],
      };

      const updated = Object.assign({}, individualNote.notes[0], { note: 'Foo' });

      mutations.UPDATE_NOTE(state, updated);

      expect(state.discussions[0].notes[0].note).toEqual('Foo');
    });

    it('transforms an individual note to discussion', () => {
      const state = {
        discussions: [individualNote],
      };

      const transformedNote = { ...individualNote.notes[0], type: DISCUSSION_NOTE };

      mutations.UPDATE_NOTE(state, transformedNote);

      expect(state.discussions[0].individual_note).toEqual(false);
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
      const state = {};
      Vue.set(state, 'discussions', [
        {
          id: 1,
          expanded: false,
        },
      ]);
      const discussion = state.discussions[0];

      mutations.SET_DISCUSSION_DIFF_LINES(state, {
        discussionId: 1,
        diffLines: [{ rich_text: '<span>a</span>' }],
      });

      discussion.expanded = true;

      expect(state.discussions[0].expanded).toBe(true);
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
          hasUnresolvedDiscussions: false,
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
          hasUnresolvedDiscussions: true,
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
});
