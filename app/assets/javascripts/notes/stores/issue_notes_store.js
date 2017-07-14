/* eslint-disable no-param-reassign */

import service from '../services/issue_notes_service';
import utils from './issue_notes_utils';

const findNoteObjectById = (notes, id) => notes.filter(n => n.id === id)[0];

const state = {
  notes: [],
  targetNoteHash: null,
  lastFetchedAt: null,
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
  setLastFetchedAt(storeState, fetchedAt) {
    storeState.lastFetchedAt = fetchedAt;
  },
  showPlaceholderNote(storeState, data) {
    storeState.notes.push({
      individual_note: true,
      isPlaceholderNote: true,
      placeholderType: data.isSystemNote ? 'systemNote' : 'note',
      notes: [
        {
          body: data.noteBody,
        },
      ],
    });
  },
  removePlaceholderNotes(storeState) {
    const { notes } = storeState;

    for (let i = notes.length - 1; i >= 0; i -= 1) {
      if (notes[i].isPlaceholderNote) {
        notes.splice(i, 1);
      }
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
  updateNote(context, data) {
    const { endpoint, note } = data;

    return service
      .updateNote(endpoint, note)
      .then(res => res.json())
      .then((res) => {
        context.commit('updateNote', res);
      });
  },
  replyToDiscussion(context, noteData) {
    const { endpoint, data } = noteData;

    return service
      .replyToDiscussion(endpoint, data)
      .then(res => res.json())
      .then((res) => {
        context.commit('addNewReplyToDiscussion', res);
      });
  },
  createNewNote(context, noteData) {
    const { endpoint, data } = noteData;

    return service
      .createNewNote(endpoint, data)
      .then(res => res.json())
      .then((res) => {
        if (!res.errors) {
          context.commit('addNewNote', res);
        }
        return res;
      });
  },
  saveNote(context, noteData) {
    const { note } = noteData.data.note;
    let placeholderText = note;
    const hasQuickActions = utils.hasQuickActions(placeholderText);

    if (hasQuickActions) {
      placeholderText = utils.stripQuickActions(placeholderText);
    }

    if (placeholderText.length) {
      context.commit('showPlaceholderNote', {
        noteBody: placeholderText,
      });
    }

    if (hasQuickActions) {
      context.commit('showPlaceholderNote', {
        isSystemNote: true,
        noteBody: utils.getQuickActionText(note),
      });
    }

    const hasReplyId = noteData.data.in_reply_to_discussion_id;
    const methodToDispatch = hasReplyId ? 'replyToDiscussion' : 'createNewNote';

    return context.dispatch(methodToDispatch, noteData)
      .then((res) => {
        const { errors } = res;

        if (hasQuickActions) {
          context.dispatch('poll');
          $('.js-gfm-input').trigger('clear-commands-cache.atwho');
          new Flash('Commands applied', 'notice', $(noteData.flashContainer)); // eslint-disable-line
        }

        if (errors && errors.commands_only) {
          new Flash(errors.commands_only, 'notice', $(noteData.flashContainer)); // eslint-disable-line
        }
        context.commit('removePlaceholderNotes');

        return res;
      });
  },
  poll(context) {
    const { notesPath } = $('.js-notes-wrapper')[0].dataset;

    return service
      .poll(`${notesPath}?full_data=1`, context.state.lastFetchedAt)
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
    const { endpoint, awardName, noteId, skipMutalityCheck } = data;
    const note = context.getters.notesById[noteId];

    return service
      .toggleAward(endpoint, { name: awardName })
      .then(res => res.json())
      .then(() => {
        context.commit('toggleAward', { awardName, note });

        if (!skipMutalityCheck && (awardName === 'thumbsup' || awardName === 'thumbsdown')) {
          const counterAward = awardName === 'thumbsup' ? 'thumbsdown' : 'thumbsup';
          const targetNote = context.getters.notesById[noteId];
          let amIAwarded = false;

          targetNote.award_emoji.forEach((a) => {
            if (a.name === counterAward && a.user.id === window.gon.current_user_id) {
              amIAwarded = true;
            }
          });

          if (amIAwarded) {
            data.awardName = counterAward;
            data.skipMutalityCheck = true;
            context.dispatch('toggleAward', data);
          }
        }
      });
  },
  scrollToNoteIfNeeded(context, el) {
    const isInViewport = gl.utils.isInViewport(el[0]);

    if (!isInViewport) {
      gl.utils.scrollToElement(el);
    }
  },
};

export default {
  state,
  getters,
  mutations,
  actions,
};
