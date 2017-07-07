/* eslint-disable no-param-reassign */

import service from '../services/issue_notes_service';

const findNoteObjectById = (notes, id) => notes.filter(n => n.id === id)[0];

const state = {
  notes: [],
  targetNoteHash: null,
};

const getters = {
  notes(storeState) {
    return storeState.notes;
  },
  targetNoteHash(storeState) {
    return storeState.targetNoteHash;
  },
  notesById(storeState) {
    const notesById = {};

    storeState.notes.forEach((note) => {
      note.notes.forEach((n) => {
        notesById[n.id] = n;
      });
    });

    return notesById;
  },
};

const mutations = {
  setInitialNotes(storeState, notes) {
    storeState.notes = notes;
  },
  setTargetNoteHash(storeState, hash) {
    storeState.targetNoteHash = hash;
  },
  toggleDiscussion(storeState, { discussionId }) {
    const discussion = findNoteObjectById(storeState.notes, discussionId);

    discussion.expanded = !discussion.expanded;
  },
  deleteNote(storeState, note) {
    const noteObj = findNoteObjectById(storeState.notes, note.discussion_id);

    if (noteObj.individual_note) {
      storeState.notes.splice(storeState.notes.indexOf(noteObj), 1);
    } else {
      const comment = findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1);

      if (!noteObj.notes.length) {
        storeState.notes.splice(storeState.notes.indexOf(noteObj), 1);
      }
    }
  },
  addNewReplyToDiscussion(storeState, note) {
    const noteObj = findNoteObjectById(storeState.notes, note.discussion_id);

    if (noteObj) {
      noteObj.notes.push(note);
    }
  },
  updateNote(storeState, note) {
    const noteObj = findNoteObjectById(storeState.notes, note.discussion_id);

    if (noteObj.individual_note) {
      noteObj.notes.splice(0, 1, note);
    } else {
      const comment = findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1, note);
    }
  },
  addNewNote(storeState, note) {
    const { discussion_id, type } = note;
    const noteData = {
      expanded: true,
      id: discussion_id,
      individual_note: !(type === 'DiscussionNote'),
      notes: [note],
      reply_id: discussion_id,
    };

    storeState.notes.push(noteData);
  },
  toggleAward(storeState, data) {
    const { awardName, note } = data;
    const { id, name, username } = window.gl.currentUserData;
    let index = -1;

    note.award_emoji.forEach((a, i) => {
      if (a.name === awardName && a.user.id === id) {
        index = i;
      }
    });

    if (index > -1) { // if I am awarded, remove my award
      note.award_emoji.splice(index, 1);
    } else {
      note.award_emoji.push({
        name: awardName,
        user: { id, name, username },
      });
    }
  },
};

const actions = {
  fetchNotes(context, path) {
    return service
      .fetchNotes(path)
      .then(res => res.json())
      .then((res) => {
        context.commit('setInitialNotes', res);
      });
  },
  deleteNote(context, note) {
    return service
      .deleteNote(note.path)
      .then(() => {
        context.commit('deleteNote', note);
      });
  },
  replyToDiscussion(context, data) {
    const { endpoint, reply } = data;

    return service
      .replyToDiscussion(endpoint, reply)
      .then(res => res.json())
      .then((res) => {
        context.commit('addNewReplyToDiscussion', res);
      });
  },
  updateNote(context, data) {
    const { endpoint, note } = data;

    return service
      .updateNote(endpoint, note)
      .then(res => res.json())
      .then((res) => {
        context.commit('updateNote', res);
      });
  },
  createNewNote(context, data) {
    const { endpoint, noteData } = data;

    return service
      .createNewNote(endpoint, noteData)
      .then(res => res.json())
      .then((res) => {
        if (!res.errors) {
          context.commit('addNewNote', res);
        }
        return res;
      });
  },
  poll(context, data) {
    const { endpoint, lastFetchedAt } = data;

    return service
      .poll(endpoint, lastFetchedAt)
      .then(res => res.json())
      .then((res) => {
        if (res.notes.length) {
          const { notesById } = context.getters;

          res.notes.forEach((note) => {
            if (notesById[note.id]) {
              context.commit('updateNote', note);
            } else if (note.type === 'DiscussionNote') {
              const discussion = findNoteObjectById(context.state.notes, note.discussion_id);

              if (discussion) {
                context.commit('addNewReplyToDiscussion', note);
              } else {
                context.commit('addNewNote', note);
              }
            } else {
              context.commit('addNewNote', note);
            }
          });
        }

        return res;
      });
  },
  toggleAward(context, data) {
    const { endpoint, awardName, noteId } = data;
    const note = context.getters.notesById[noteId];

    return service
      .toggleAward(endpoint, { name: awardName })
      .then(res => res.json())
      .then(() => {
        context.commit('toggleAward', { awardName, note });
      });
  },
};

export default {
  state,
  getters,
  mutations,
  actions,
};
