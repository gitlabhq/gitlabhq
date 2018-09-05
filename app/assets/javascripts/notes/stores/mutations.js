import * as utils from './utils';
import * as types from './mutation_types';
import * as constants from '../constants';
import { isInMRPage } from '../../lib/utils/common_utils';

export default {
  [types.ADD_NEW_NOTE](state, note) {
    const { discussion_id, type } = note;
    const [exists] = state.discussions.filter(n => n.id === note.discussion_id);
    const isDiscussion = type === constants.DISCUSSION_NOTE || type === constants.DIFF_NOTE;

    if (!exists) {
      const noteData = {
        expanded: true,
        id: discussion_id,
        individual_note: !isDiscussion,
        notes: [note],
        reply_id: discussion_id,
      };

      if (isDiscussion && isInMRPage()) {
        noteData.resolvable = note.resolvable;
        noteData.resolved = false;
        noteData.resolve_path = note.resolve_path;
        noteData.resolve_with_issue_path = note.resolve_with_issue_path;
      }

      state.discussions.push(noteData);
    }
  },

  [types.ADD_NEW_REPLY_TO_DISCUSSION](state, note) {
    const noteObj = utils.findNoteObjectById(state.discussions, note.discussion_id);

    if (noteObj) {
      noteObj.notes.push(note);
    }
  },

  [types.DELETE_NOTE](state, note) {
    const noteObj = utils.findNoteObjectById(state.discussions, note.discussion_id);

    if (noteObj.individual_note) {
      state.discussions.splice(state.discussions.indexOf(noteObj), 1);
    } else {
      const comment = utils.findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1);

      if (!noteObj.notes.length) {
        state.discussions.splice(state.discussions.indexOf(noteObj), 1);
      }
    }
  },

  [types.EXPAND_DISCUSSION](state, { discussionId }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);

    discussion.expanded = true;
  },

  [types.COLLAPSE_DISCUSSION](state, { discussionId }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);
    discussion.expanded = false;
  },

  [types.REMOVE_PLACEHOLDER_NOTES](state) {
    const { discussions } = state;

    for (let i = discussions.length - 1; i >= 0; i -= 1) {
      const note = discussions[i];
      const children = note.notes;

      if (children.length && !note.individual_note) {
        // remove placeholder from discussions
        for (let j = children.length - 1; j >= 0; j -= 1) {
          if (children[j].isPlaceholderNote) {
            children.splice(j, 1);
          }
        }
      } else if (note.isPlaceholderNote) {
        // remove placeholders from state root
        discussions.splice(i, 1);
      }
    }
  },

  [types.SET_NOTES_DATA](state, data) {
    Object.assign(state, { notesData: data });
  },

  [types.SET_NOTEABLE_DATA](state, data) {
    Object.assign(state, { noteableData: data });
  },

  [types.SET_USER_DATA](state, data) {
    Object.assign(state, { userData: data });
  },
  [types.SET_INITIAL_DISCUSSIONS](state, discussionsData) {
    const discussions = [];

    discussionsData.forEach(discussion => {
      // To support legacy notes, should be very rare case.
      if (discussion.individual_note && discussion.notes.length > 1) {
        discussion.notes.forEach(n => {
          discussions.push({
            ...discussion,
            notes: [n], // override notes array to only have one item to mimick individual_note
          });
        });
      } else {
        const oldNote = utils.findNoteObjectById(state.discussions, discussion.id);

        discussions.push({
          ...discussion,
          expanded: oldNote ? oldNote.expanded : discussion.expanded,
        });
      }
    });

    Object.assign(state, { discussions });
  },
  [types.SET_LAST_FETCHED_AT](state, fetchedAt) {
    Object.assign(state, { lastFetchedAt: fetchedAt });
  },

  [types.SET_TARGET_NOTE_HASH](state, hash) {
    Object.assign(state, { targetNoteHash: hash });
  },

  [types.SHOW_PLACEHOLDER_NOTE](state, data) {
    let notesArr = state.discussions;

    const existingDiscussion = utils.findNoteObjectById(notesArr, data.replyId);
    if (existingDiscussion) {
      notesArr = existingDiscussion.notes;
    }

    notesArr.push({
      individual_note: true,
      isPlaceholderNote: true,
      placeholderType: data.isSystemNote ? constants.SYSTEM_NOTE : constants.NOTE,
      notes: [
        {
          body: data.noteBody,
        },
      ],
    });
  },

  [types.TOGGLE_AWARD](state, data) {
    const { awardName, note } = data;
    const { id, name, username } = state.userData;

    const hasEmojiAwardedByCurrentUser = note.award_emoji.filter(
      emoji => emoji.name === data.awardName && emoji.user.id === id,
    );

    if (hasEmojiAwardedByCurrentUser.length) {
      // If current user has awarded this emoji, remove it.
      note.award_emoji.splice(note.award_emoji.indexOf(hasEmojiAwardedByCurrentUser[0]), 1);
    } else {
      note.award_emoji.push({
        name: awardName,
        user: { id, name, username },
      });
    }
  },

  [types.TOGGLE_DISCUSSION](state, { discussionId }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);

    discussion.expanded = !discussion.expanded;
  },

  [types.UPDATE_NOTE](state, note) {
    const noteObj = utils.findNoteObjectById(state.discussions, note.discussion_id);

    if (noteObj.individual_note) {
      noteObj.notes.splice(0, 1, note);
    } else {
      const comment = utils.findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1, note);
    }
  },

  [types.UPDATE_DISCUSSION](state, noteData) {
    const note = noteData;
    const selectedDiscussion = state.discussions.find(disc => disc.id === note.id);
    note.expanded = true; // override expand flag to prevent collapse
    Object.assign(selectedDiscussion, { ...note });
  },

  [types.CLOSE_ISSUE](state) {
    Object.assign(state.noteableData, { state: constants.CLOSED });
  },

  [types.REOPEN_ISSUE](state) {
    Object.assign(state.noteableData, { state: constants.REOPENED });
  },

  [types.TOGGLE_STATE_BUTTON_LOADING](state, value) {
    Object.assign(state, { isToggleStateButtonLoading: value });
  },

  [types.SET_NOTES_FETCHED_STATE](state, value) {
    Object.assign(state, { isNotesFetched: value });
  },

  [types.SET_DISCUSSION_DIFF_LINES](state, { discussionId, diffLines }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);
    const index = state.discussions.indexOf(discussion);

    const discussionWithDiffLines = Object.assign({}, discussion, {
      truncated_diff_lines: diffLines,
    });

    state.discussions.splice(index, 1, discussionWithDiffLines);
  },
};
