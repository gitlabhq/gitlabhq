/* global Flash */

import * as types from './mutation_types';
import * as utils from './utils';
import * as constants from '../constants';
import service from '../services/issue_notes_service';
import loadAwardsHandler from '../../awards_handler';
import sidebarTimeTrackingEventHub from '../../sidebar/event_hub';

export const fetchNotes = ({ commit }, path) => service
  .fetchNotes(path)
  .then(res => res.json())
  .then((res) => {
    commit(types.SET_INITAL_NOTES, res);
  });

export const deleteNote = ({ commit }, note) => service
  .deleteNote(note.path)
  .then(() => {
    commit(types.DELETE_NOTE, note);
  });

export const updateNote = ({ commit }, data) => {
  const { endpoint, note } = data;

  return service
    .updateNote(endpoint, note)
    .then(res => res.json())
    .then((res) => {
      commit(types.UPDATE_NOTE, res);
    });
};

export const replyToDiscussion = ({ commit }, note) => {
  const { endpoint, data } = note;

  return service
    .replyToDiscussion(endpoint, data)
    .then(res => res.json())
    .then((res) => {
      commit(types.ADD_NEW_REPLY_TO_DISCUSSION, res);

      return res;
    });
};

export const createNewNote = ({ commit }, note) => {
  const { endpoint, data } = note;

  return service
    .createNewNote(endpoint, data)
    .then(res => res.json())
    .then((res) => {
      if (!res.errors) {
        commit(types.ADD_NEW_NOTE, res);
      }
      return res;
    });
};

export const saveNote = ({ commit, dispatch }, noteData) => {
  const { note } = noteData.data.note;
  let placeholderText = note;
  const hasQuickActions = utils.hasQuickActions(placeholderText);
  const replyId = noteData.data.in_reply_to_discussion_id;
  const methodToDispatch = replyId ? 'replyToDiscussion' : 'createNewNote';

  if (hasQuickActions) {
    placeholderText = utils.stripQuickActions(placeholderText);
  }

  if (placeholderText.length) {
    commit(types.SHOW_PLACEHOLDER_NOTE, {
      noteBody: placeholderText,
      replyId,
    });
  }

  if (hasQuickActions) {
    commit(types.SHOW_PLACEHOLDER_NOTE, {
      isSystemNote: true,
      noteBody: utils.getQuickActionText(note),
      replyId,
    });
  }

  return dispatch(methodToDispatch, noteData)
    .then((res) => {
      const { errors } = res;
      const commandsChanges = res.commands_changes;

      if (hasQuickActions && Object.keys(errors).length) {
        dispatch('poll');
        $('.js-gfm-input').trigger('clear-commands-cache.atwho');
        Flash('Commands applied', 'notice', $(noteData.flashContainer));
      }

      if (commandsChanges) {
        if (commandsChanges.emoji_award) {
          const votesBlock = $('.js-awards-block').eq(0);

          loadAwardsHandler()
            .then((awardsHandler) => {
              awardsHandler.addAwardToEmojiBar(votesBlock, commandsChanges.emoji_award);
              awardsHandler.scrollToAwards();
            })
            .catch(() => {
              Flash(
                'Something went wrong while adding your award. Please try again.',
                null,
                $(noteData.flashContainer),
              );
            });
        }

        if (commandsChanges.spend_time != null || commandsChanges.time_estimate != null) {
          sidebarTimeTrackingEventHub.$emit('timeTrackingUpdated', res);
        }
      }

      if (errors && errors.commands_only) {
        Flash(errors.commands_only, 'notice', $(noteData.flashContainer));
      }
      commit(types.REMOVE_PLACEHOLDER_NOTES);

      return res;
    })
    .catch(() => {
      Flash(
        'Your comment could not be submitted! Please check your network connection and try again.',
        'alert',
        $(noteData.flashContainer),
      );
      commit(types.REMOVE_PLACEHOLDER_NOTES);
    });
};

export const poll = ({ commit, state, getters }) => {
  const { notesPath } = $('.js-notes-wrapper')[0].dataset;

  return service
    .poll(`${notesPath}?full_data=1`, state.lastFetchedAt)
    .then(res => res.json())
    .then((res) => {
      if (res.notes.length) {
        const { notesById } = getters;

        res.notes.forEach((note) => {
          if (notesById[note.id]) {
            commit(types.UPDATE_NOTE, note);
          } else if (note.type === constants.DISCUSSION_NOTE) {
            const discussion = utils.findNoteObjectById(state.notes, note.discussion_id);

            if (discussion) {
              commit(types.ADD_NEW_REPLY_TO_DISCUSSION, note);
            } else {
              commit(types.ADD_NEW_NOTE, note);
            }
          } else {
            commit(types.ADD_NEW_NOTE, note);
          }
        });
      }

      return res;
    });
};

export const toggleAward = ({ commit, getters, dispatch }, data) => {
  const { endpoint, awardName, noteId, skipMutalityCheck } = data;
  const note = getters.notesById[noteId];

  return service
    .toggleAward(endpoint, { name: awardName })
    .then(res => res.json())
    .then(() => {
      commit(types.TOGGLE_AWARD, { awardName, note });

      if (!skipMutalityCheck && (awardName === 'thumbsup' || awardName === 'thumbsdown')) {
        const counterAward = awardName === 'thumbsup' ? 'thumbsdown' : 'thumbsup';
        const targetNote = getters.notesById[noteId];
        let amIAwarded = false;

        targetNote.award_emoji.forEach((a) => {
          if (a.name === counterAward && a.user.id === window.gon.current_user_id) {
            amIAwarded = true;
          }
        });

        if (amIAwarded) {
          Object.assign(data, { awardName: counterAward });
          Object.assign(data, { skipMutalityCheck: true });

          dispatch(types.TOGGLE_AWARD, data);
        }
      }
    });
};

export const scrollToNoteIfNeeded = (context, el) => {
  const isInViewport = gl.utils.isInViewport(el[0]);

  if (!isInViewport) {
    gl.utils.scrollToElement(el);
  }
};
