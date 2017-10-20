import * as utils from './utils';
import * as types from './mutation_types';
import * as constants from '../constants';

export default {
  [types.ADD_NEW_NOTE](state, note) {
    const { discussion_id, type } = note;
    const [exists] = state.notes.filter(n => n.id === note.discussion_id);

    if (!exists) {
      const noteData = {
        expanded: true,
        id: discussion_id,
        individual_note: !(type === constants.DISCUSSION_NOTE),
        notes: [note],
        reply_id: discussion_id,
      };

      state.notes.push(noteData);
    }
  },

  [types.ADD_NEW_REPLY_TO_DISCUSSION](state, note) {
    const noteObj = utils.findNoteObjectById(state.notes, note.discussion_id);

    if (noteObj) {
      noteObj.notes.push(note);
    }
  },

  [types.DELETE_NOTE](state, note) {
    const noteObj = utils.findNoteObjectById(state.notes, note.discussion_id);

    if (noteObj.individual_note) {
      state.notes.splice(state.notes.indexOf(noteObj), 1);
    } else {
      const comment = utils.findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1);

      if (!noteObj.notes.length) {
        state.notes.splice(state.notes.indexOf(noteObj), 1);
      }
    }
  },

  [types.REMOVE_PLACEHOLDER_NOTES](state) {
    const { notes } = state;

    for (let i = notes.length - 1; i >= 0; i -= 1) {
      const note = notes[i];
      const children = note.notes;

      if (children.length && !note.individual_note) { // remove placeholder from discussions
        for (let j = children.length - 1; j >= 0; j -= 1) {
          if (children[j].isPlaceholderNote) {
            children.splice(j, 1);
          }
        }
      } else if (note.isPlaceholderNote) { // remove placeholders from state root
        notes.splice(i, 1);
      }
    }
  },

  [types.SET_NOTES_DATA](state, data) {
    Object.assign(state, { notesData: data });
  },

  [types.SET_ISSUE_DATA](state, data) {
    Object.assign(state, { issueData: data });
  },

  [types.SET_USER_DATA](state, data) {
    Object.assign(state, { userData: data });
  },
  [types.SET_INITIAL_NOTES](state, notesData) {
    const notes = [];

    notesData.forEach((note) => {
      // To support legacy notes, should be very rare case.
      if (note.individual_note && note.notes.length > 1) {
        note.notes.forEach((n) => {
          const nn = Object.assign({}, note);
          nn.notes = [n]; // override notes array to only have one item to mimick individual_note
          notes.push(nn);
        });
      } else {
        notes.push(note);
      }
    });

    Object.assign(state, { notes });
  },

  [types.SET_LAST_FETCHED_AT](state, fetchedAt) {
    Object.assign(state, { lastFetchedAt: fetchedAt });
  },

  [types.SET_TARGET_NOTE_HASH](state, hash) {
    Object.assign(state, { targetNoteHash: hash });
  },

  [types.SHOW_PLACEHOLDER_NOTE](state, data) {
    let notesArr = state.notes;
    if (data.replyId) {
      notesArr = utils.findNoteObjectById(notesArr, data.replyId).notes;
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

    const hasEmojiAwardedByCurrentUser = note.award_emoji
      .filter(emoji => emoji.name === data.awardName && emoji.user.id === id);

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
    const discussion = utils.findNoteObjectById(state.notes, discussionId);

    discussion.expanded = !discussion.expanded;
  },

  [types.UPDATE_NOTE](state, note) {
    const noteObj = utils.findNoteObjectById(state.notes, note.discussion_id);

    if (noteObj.individual_note) {
      noteObj.notes.splice(0, 1, note);
    } else {
      const comment = utils.findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1, note);
    }
  },
};
