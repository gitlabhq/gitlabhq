import $ from 'jquery';
import Visibility from 'visibilityjs';
import Flash from '../../flash';
import Poll from '../../lib/utils/poll';
import * as types from './mutation_types';
import * as utils from './utils';
import * as constants from '../constants';
import service from '../services/notes_service';
import loadAwardsHandler from '../../awards_handler';
import sidebarTimeTrackingEventHub from '../../sidebar/event_hub';
import { isInViewport, scrollToElement } from '../../lib/utils/common_utils';

let eTagPoll;

export const setNotesData = ({ commit }, data) =>
  commit(types.SET_NOTES_DATA, data);
export const setNoteableData = ({ commit }, data) =>
  commit(types.SET_NOTEABLE_DATA, data);
export const setUserData = ({ commit }, data) =>
  commit(types.SET_USER_DATA, data);
export const setLastFetchedAt = ({ commit }, data) =>
  commit(types.SET_LAST_FETCHED_AT, data);
export const setInitialNotes = ({ commit }, data) =>
  commit(types.SET_INITIAL_NOTES, data);
export const setTargetNoteHash = ({ commit }, data) =>
  commit(types.SET_TARGET_NOTE_HASH, data);
export const toggleDiscussion = ({ commit }, data) =>
  commit(types.TOGGLE_DISCUSSION, data);

export const fetchNotes = ({ commit }, path) =>
  service
    .fetchNotes(path)
    .then(res => res.json())
    .then(res => {
      commit(types.SET_INITIAL_NOTES, res);
    });

export const deleteNote = ({ commit }, note) =>
  service.deleteNote(note.path).then(() => {
    commit(types.DELETE_NOTE, note);
  });

export const updateNote = ({ commit }, { endpoint, note }) =>
  service
    .updateNote(endpoint, note)
    .then(res => res.json())
    .then(res => {
      commit(types.UPDATE_NOTE, res);
    });

export const replyToDiscussion = ({ commit }, { endpoint, data }) =>
  service
    .replyToDiscussion(endpoint, data)
    .then(res => res.json())
    .then(res => {
      commit(types.ADD_NEW_REPLY_TO_DISCUSSION, res);

      return res;
    });

export const createNewNote = ({ commit }, { endpoint, data }) =>
  service
    .createNewNote(endpoint, data)
    .then(res => res.json())
    .then(res => {
      if (!res.errors) {
        commit(types.ADD_NEW_NOTE, res);
      }
      return res;
    });

export const removePlaceholderNotes = ({ commit }) =>
  commit(types.REMOVE_PLACEHOLDER_NOTES);

export const toggleResolveNote = (
  { commit },
  { endpoint, isResolved, discussion },
) =>
  service
    .toggleResolveNote(endpoint, isResolved)
    .then(res => res.json())
    .then(res => {
      const mutationType = discussion
        ? types.UPDATE_DISCUSSION
        : types.UPDATE_NOTE;

      commit(mutationType, res);
    });

export const closeIssue = ({ commit, dispatch, state }) => {
  dispatch('toggleStateButtonLoading', true);
  return service
    .toggleIssueState(state.notesData.closePath)
    .then(res => res.json())
    .then(data => {
      commit(types.CLOSE_ISSUE);
      dispatch('emitStateChangedEvent', data);
      dispatch('toggleStateButtonLoading', false);
    });
};

export const reopenIssue = ({ commit, dispatch, state }) => {
  dispatch('toggleStateButtonLoading', true);
  return service
    .toggleIssueState(state.notesData.reopenPath)
    .then(res => res.json())
    .then(data => {
      commit(types.REOPEN_ISSUE);
      dispatch('emitStateChangedEvent', data);
      dispatch('toggleStateButtonLoading', false);
    });
};

export const toggleStateButtonLoading = ({ commit }, value) =>
  commit(types.TOGGLE_STATE_BUTTON_LOADING, value);

export const emitStateChangedEvent = ({ commit, getters }, data) => {
  const event = new CustomEvent('issuable_vue_app:change', {
    detail: {
      data,
      isClosed: getters.openState === constants.CLOSED,
    },
  });

  document.dispatchEvent(event);
};

export const toggleIssueLocalState = ({ commit }, newState) => {
  if (newState === constants.CLOSED) {
    commit(types.CLOSE_ISSUE);
  } else if (newState === constants.REOPENED) {
    commit(types.REOPEN_ISSUE);
  }
};

export const saveNote = ({ commit, dispatch }, noteData) => {
  const { note } = noteData.data.note;
  let placeholderText = note;
  const hasQuickActions = utils.hasQuickActions(placeholderText);
  const replyId = noteData.data.in_reply_to_discussion_id;
  const methodToDispatch = replyId ? 'replyToDiscussion' : 'createNewNote';

  commit(types.REMOVE_PLACEHOLDER_NOTES); // remove previous placeholders
  $('.notes-form .flash-container').hide(); // hide previous flash notification

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

  return dispatch(methodToDispatch, noteData).then(res => {
    const { errors } = res;
    const commandsChanges = res.commands_changes;

    if (hasQuickActions && errors && Object.keys(errors).length) {
      eTagPoll.makeRequest();

      $('.js-gfm-input').trigger('clear-commands-cache.atwho');
      Flash('Commands applied', 'notice', noteData.flashContainer);
    }

    if (commandsChanges) {
      if (commandsChanges.emoji_award) {
        const votesBlock = $('.js-awards-block').eq(0);

        loadAwardsHandler()
          .then(awardsHandler => {
            awardsHandler.addAwardToEmojiBar(
              votesBlock,
              commandsChanges.emoji_award,
            );
            awardsHandler.scrollToAwards();
          })
          .catch(() => {
            Flash(
              'Something went wrong while adding your award. Please try again.',
              'alert',
              noteData.flashContainer,
            );
          });
      }

      if (
        commandsChanges.spend_time != null ||
        commandsChanges.time_estimate != null
      ) {
        sidebarTimeTrackingEventHub.$emit('timeTrackingUpdated', res);
      }
    }

    if (errors && errors.commands_only) {
      Flash(errors.commands_only, 'notice', noteData.flashContainer);
    }
    commit(types.REMOVE_PLACEHOLDER_NOTES);

    return res;
  });
};

const pollSuccessCallBack = (resp, commit, state, getters) => {
  if (resp.notes && resp.notes.length) {
    const { notesById } = getters;

    resp.notes.forEach(note => {
      if (notesById[note.id]) {
        commit(types.UPDATE_NOTE, note);
      } else if (
        note.type === constants.DISCUSSION_NOTE ||
        note.type === constants.DIFF_NOTE
      ) {
        const discussion = utils.findNoteObjectById(
          state.notes,
          note.discussion_id,
        );

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

  commit(types.SET_LAST_FETCHED_AT, resp.last_fetched_at);

  return resp;
};

export const poll = ({ commit, state, getters }) => {
  eTagPoll = new Poll({
    resource: service,
    method: 'poll',
    data: state,
    successCallback: resp =>
      resp
        .json()
        .then(data => pollSuccessCallBack(data, commit, state, getters)),
    errorCallback: () =>
      Flash('Something went wrong while fetching latest comments.'),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeRequest();
  } else {
    service.poll(state);
  }

  Visibility.change(() => {
    if (!Visibility.hidden()) {
      eTagPoll.restart();
    } else {
      eTagPoll.stop();
    }
  });
};

export const stopPolling = () => {
  eTagPoll.stop();
};

export const restartPolling = () => {
  eTagPoll.restart();
};

export const fetchData = ({ commit, state, getters }) => {
  const requestData = {
    endpoint: state.notesData.notesPath,
    lastFetchedAt: state.lastFetchedAt,
  };

  service
    .poll(requestData)
    .then(resp => resp.json)
    .then(data => pollSuccessCallBack(data, commit, state, getters))
    .catch(() => Flash('Something went wrong while fetching latest comments.'));
};

export const toggleAward = (
  { commit, state, getters, dispatch },
  { awardName, noteId },
) => {
  commit(types.TOGGLE_AWARD, { awardName, note: getters.notesById[noteId] });
};

export const toggleAwardRequest = ({ commit, getters, dispatch }, data) => {
  const { endpoint, awardName } = data;

  return service
    .toggleAward(endpoint, { name: awardName })
    .then(res => res.json())
    .then(() => {
      dispatch('toggleAward', data);
    });
};

export const scrollToNoteIfNeeded = (context, el) => {
  if (!isInViewport(el[0])) {
    scrollToElement(el);
  }
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
