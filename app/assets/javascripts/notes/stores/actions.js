import Vue from 'vue';
import $ from 'jquery';
import Visibility from 'visibilityjs';
import axios from '~/lib/utils/axios_utils';
import TaskList from '../../task_list';
import Flash from '../../flash';
import Poll from '../../lib/utils/poll';
import * as types from './mutation_types';
import * as utils from './utils';
import * as constants from '../constants';
import service from '../services/notes_service';
import loadAwardsHandler from '../../awards_handler';
import sidebarTimeTrackingEventHub from '../../sidebar/event_hub';
import { isInViewport, scrollToElement, isInMRPage } from '../../lib/utils/common_utils';
import { mergeUrlParams } from '../../lib/utils/url_utility';
import mrWidgetEventHub from '../../vue_merge_request_widget/event_hub';
import { __, sprintf } from '~/locale';
import Api from '~/api';

let eTagPoll;

export const expandDiscussion = ({ commit, dispatch }, data) => {
  if (data.discussionId) {
    dispatch('diffs/renderFileForDiscussionId', data.discussionId, { root: true });
  }

  commit(types.EXPAND_DISCUSSION, data);
};

export const collapseDiscussion = ({ commit }, data) => commit(types.COLLAPSE_DISCUSSION, data);

export const setNotesData = ({ commit }, data) => commit(types.SET_NOTES_DATA, data);

export const setNoteableData = ({ commit }, data) => commit(types.SET_NOTEABLE_DATA, data);

export const setUserData = ({ commit }, data) => commit(types.SET_USER_DATA, data);

export const setLastFetchedAt = ({ commit }, data) => commit(types.SET_LAST_FETCHED_AT, data);

export const setInitialNotes = ({ commit }, discussions) =>
  commit(types.SET_INITIAL_DISCUSSIONS, discussions);

export const setTargetNoteHash = ({ commit }, data) => commit(types.SET_TARGET_NOTE_HASH, data);

export const setNotesFetchedState = ({ commit }, state) =>
  commit(types.SET_NOTES_FETCHED_STATE, state);

export const toggleDiscussion = ({ commit }, data) => commit(types.TOGGLE_DISCUSSION, data);

export const fetchDiscussions = ({ commit, dispatch }, { path, filter, persistFilter }) =>
  service.fetchDiscussions(path, filter, persistFilter).then(({ data }) => {
    commit(types.SET_INITIAL_DISCUSSIONS, data);
    dispatch('updateResolvableDiscussionsCounts');
  });

export const updateDiscussion = ({ commit, state }, discussion) => {
  commit(types.UPDATE_DISCUSSION, discussion);

  return utils.findNoteObjectById(state.discussions, discussion.id);
};

export const removeNote = ({ commit, dispatch, state }, note) => {
  const discussion = state.discussions.find(({ id }) => id === note.discussion_id);

  commit(types.DELETE_NOTE, note);

  dispatch('updateMergeRequestWidget');
  dispatch('updateResolvableDiscussionsCounts');

  if (isInMRPage()) {
    dispatch('diffs/removeDiscussionsFromDiff', discussion);
  }
};

export const deleteNote = ({ dispatch }, note) =>
  axios.delete(note.path).then(() => {
    dispatch('removeNote', note);
  });

export const updateNote = ({ commit, dispatch }, { endpoint, note }) =>
  service.updateNote(endpoint, note).then(({ data }) => {
    commit(types.UPDATE_NOTE, data);
    dispatch('startTaskList');
  });

export const updateOrCreateNotes = ({ commit, state, getters, dispatch }, notes) => {
  const { notesById } = getters;

  notes.forEach(note => {
    if (notesById[note.id]) {
      commit(types.UPDATE_NOTE, note);
    } else if (note.type === constants.DISCUSSION_NOTE || note.type === constants.DIFF_NOTE) {
      const discussion = utils.findNoteObjectById(state.discussions, note.discussion_id);

      if (discussion) {
        commit(types.ADD_NEW_REPLY_TO_DISCUSSION, note);
      } else if (note.type === constants.DIFF_NOTE) {
        dispatch('fetchDiscussions', { path: state.notesData.discussionsPath });
      } else {
        commit(types.ADD_NEW_NOTE, note);
      }
    } else {
      commit(types.ADD_NEW_NOTE, note);
    }
  });
};

export const replyToDiscussion = (
  { commit, state, getters, dispatch },
  { endpoint, data: reply },
) =>
  service.replyToDiscussion(endpoint, reply).then(({ data }) => {
    if (data.discussion) {
      commit(types.UPDATE_DISCUSSION, data.discussion);

      updateOrCreateNotes({ commit, state, getters, dispatch }, data.discussion.notes);

      dispatch('updateMergeRequestWidget');
      dispatch('startTaskList');
      dispatch('updateResolvableDiscussionsCounts');
    } else {
      commit(types.ADD_NEW_REPLY_TO_DISCUSSION, data);
    }

    return data;
  });

export const createNewNote = ({ commit, dispatch }, { endpoint, data: reply }) =>
  service.createNewNote(endpoint, reply).then(({ data }) => {
    if (!data.errors) {
      commit(types.ADD_NEW_NOTE, data);

      dispatch('updateMergeRequestWidget');
      dispatch('startTaskList');
      dispatch('updateResolvableDiscussionsCounts');
    }
    return data;
  });

export const removePlaceholderNotes = ({ commit }) => commit(types.REMOVE_PLACEHOLDER_NOTES);

export const resolveDiscussion = ({ state, dispatch, getters }, { discussionId }) => {
  const discussion = utils.findNoteObjectById(state.discussions, discussionId);
  const isResolved = getters.isDiscussionResolved(discussionId);

  if (!discussion) {
    return Promise.reject();
  } else if (isResolved) {
    return Promise.resolve();
  }

  return dispatch('toggleResolveNote', {
    endpoint: discussion.resolve_path,
    isResolved,
    discussion: true,
  });
};

export const toggleResolveNote = ({ commit, dispatch }, { endpoint, isResolved, discussion }) =>
  service.toggleResolveNote(endpoint, isResolved).then(({ data }) => {
    const mutationType = discussion ? types.UPDATE_DISCUSSION : types.UPDATE_NOTE;

    commit(mutationType, data);

    dispatch('updateResolvableDiscussionsCounts');

    dispatch('updateMergeRequestWidget');
  });

export const closeIssue = ({ commit, dispatch, state }) => {
  dispatch('toggleStateButtonLoading', true);
  return service.toggleIssueState(state.notesData.closePath).then(({ data }) => {
    commit(types.CLOSE_ISSUE);
    dispatch('emitStateChangedEvent', data);
    dispatch('toggleStateButtonLoading', false);
  });
};

export const reopenIssue = ({ commit, dispatch, state }) => {
  dispatch('toggleStateButtonLoading', true);
  return service.toggleIssueState(state.notesData.reopenPath).then(({ data }) => {
    commit(types.REOPEN_ISSUE);
    dispatch('emitStateChangedEvent', data);
    dispatch('toggleStateButtonLoading', false);
  });
};

export const toggleStateButtonLoading = ({ commit }, value) =>
  commit(types.TOGGLE_STATE_BUTTON_LOADING, value);

export const emitStateChangedEvent = ({ getters }, data) => {
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
  // For MR discussuions we need to post as `note[note]` and issue we use `note.note`.
  // For batch comments, we use draft_note
  const note = noteData.data.draft_note || noteData.data['note[note]'] || noteData.data.note.note;
  let placeholderText = note;
  const hasQuickActions = utils.hasQuickActions(placeholderText);
  const replyId = noteData.data.in_reply_to_discussion_id;
  let methodToDispatch;
  const postData = Object.assign({}, noteData);
  if (postData.isDraft === true) {
    methodToDispatch = replyId
      ? 'batchComments/addDraftToDiscussion'
      : 'batchComments/createNewDraft';
    if (!postData.draft_note && noteData.note) {
      postData.draft_note = postData.note;
      delete postData.note;
    }
  } else {
    methodToDispatch = replyId ? 'replyToDiscussion' : 'createNewNote';
  }

  $('.notes-form .flash-container').hide(); // hide previous flash notification
  commit(types.REMOVE_PLACEHOLDER_NOTES); // remove previous placeholders

  if (replyId) {
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
  }

  const processQuickActions = res => {
    const { errors: { commands_only: message } = { commands_only: null } } = res;
    /*
     The following reply means that quick actions have been successfully applied:

     {"commands_changes":{},"valid":false,"errors":{"commands_only":["Commands applied"]}}
     */
    if (hasQuickActions && message) {
      eTagPoll.makeRequest();

      $('.js-gfm-input').trigger('clear-commands-cache.atwho');

      Flash(message || __('Commands applied'), 'notice', noteData.flashContainer);
    }

    return res;
  };

  const processEmojiAward = res => {
    const { commands_changes: commandsChanges } = res;
    const { emoji_award: emojiAward } = commandsChanges || {};
    if (!emojiAward) {
      return res;
    }

    const votesBlock = $('.js-awards-block').eq(0);

    return loadAwardsHandler()
      .then(awardsHandler => {
        awardsHandler.addAwardToEmojiBar(votesBlock, emojiAward);
        awardsHandler.scrollToAwards();
      })
      .catch(() => {
        Flash(
          __('Something went wrong while adding your award. Please try again.'),
          'alert',
          noteData.flashContainer,
        );
      })
      .then(() => res);
  };

  const processTimeTracking = res => {
    const { commands_changes: commandsChanges } = res;
    const { spend_time: spendTime, time_estimate: timeEstimate } = commandsChanges || {};
    if (spendTime != null || timeEstimate != null) {
      sidebarTimeTrackingEventHub.$emit('timeTrackingUpdated', {
        commands_changes: commandsChanges,
      });
    }

    return res;
  };

  const removePlaceholder = res => {
    if (replyId) {
      commit(types.REMOVE_PLACEHOLDER_NOTES);
    }

    return res;
  };

  const processErrors = error => {
    if (error.response) {
      const {
        response: { data = {} },
      } = error;
      const { errors = {} } = data;
      const { base = [] } = errors;

      // we handle only errors.base for now
      if (base.length > 0) {
        const errorMsg = sprintf(__('Your comment could not be submitted because %{error}'), {
          error: base[0].toLowerCase(),
        });
        Flash(errorMsg, 'alert', noteData.flashContainer);
        return { ...data, hasFlash: true };
      }
    }

    throw error;
  };

  return dispatch(methodToDispatch, postData, { root: true })
    .then(processQuickActions)
    .then(processEmojiAward)
    .then(processTimeTracking)
    .then(removePlaceholder)
    .catch(processErrors);
};

const pollSuccessCallBack = (resp, commit, state, getters, dispatch) => {
  if (resp.notes && resp.notes.length) {
    updateOrCreateNotes({ commit, state, getters, dispatch }, resp.notes);

    dispatch('startTaskList');
  }

  commit(types.SET_LAST_FETCHED_AT, resp.last_fetched_at);

  return resp;
};

export const poll = ({ commit, state, getters, dispatch }) => {
  eTagPoll = new Poll({
    resource: service,
    method: 'poll',
    data: state,
    successCallback: ({ data }) => pollSuccessCallBack(data, commit, state, getters, dispatch),
    errorCallback: () => Flash(__('Something went wrong while fetching latest comments.')),
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
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const fetchData = ({ commit, state, getters }) => {
  const requestData = {
    endpoint: state.notesData.notesPath,
    lastFetchedAt: state.lastFetchedAt,
  };

  service
    .poll(requestData)
    .then(({ data }) => pollSuccessCallBack(data, commit, state, getters))
    .catch(() => Flash(__('Something went wrong while fetching latest comments.')));
};

export const toggleAward = ({ commit, getters }, { awardName, noteId }) => {
  commit(types.TOGGLE_AWARD, { awardName, note: getters.notesById[noteId] });
};

export const toggleAwardRequest = ({ dispatch }, data) => {
  const { endpoint, awardName } = data;

  return axios.post(endpoint, { name: awardName }).then(() => {
    dispatch('toggleAward', data);
  });
};

export const scrollToNoteIfNeeded = (context, el) => {
  if (!isInViewport(el[0])) {
    scrollToElement(el);
  }
};

export const fetchDiscussionDiffLines = ({ commit }, discussion) =>
  axios.get(discussion.truncated_diff_lines_path).then(({ data }) => {
    commit(types.SET_DISCUSSION_DIFF_LINES, {
      discussionId: discussion.id,
      diffLines: data.truncated_diff_lines,
    });
  });

export const updateMergeRequestWidget = () => {
  mrWidgetEventHub.$emit('mr.discussion.updated');
};

export const setLoadingState = ({ commit }, data) => {
  commit(types.SET_NOTES_LOADING_STATE, data);
};

export const filterDiscussion = ({ dispatch }, { path, filter, persistFilter }) => {
  dispatch('setLoadingState', true);
  dispatch('fetchDiscussions', { path, filter, persistFilter })
    .then(() => {
      dispatch('setLoadingState', false);
      dispatch('setNotesFetchedState', true);
    })
    .catch(() => {
      dispatch('setLoadingState', false);
      dispatch('setNotesFetchedState', true);
      Flash(__('Something went wrong while fetching comments. Please try again.'));
    });
};

export const setCommentsDisabled = ({ commit }, data) => {
  commit(types.DISABLE_COMMENTS, data);
};

export const startTaskList = ({ dispatch }) =>
  Vue.nextTick(
    () =>
      new TaskList({
        dataType: 'note',
        fieldName: 'note',
        selector: '.notes .is-editable',
        onSuccess: () => dispatch('startTaskList'),
      }),
  );

export const updateResolvableDiscussionsCounts = ({ commit }) =>
  commit(types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS);

export const submitSuggestion = (
  { commit, dispatch },
  { discussionId, noteId, suggestionId, flashContainer },
) => {
  const dispatchResolveDiscussion = () =>
    dispatch('resolveDiscussion', { discussionId }).catch(() => {});

  return Api.applySuggestion(suggestionId)
    .then(() => commit(types.APPLY_SUGGESTION, { discussionId, noteId, suggestionId }))
    .then(dispatchResolveDiscussion)
    .catch(err => {
      const defaultMessage = __(
        'Something went wrong while applying the suggestion. Please try again.',
      );
      const flashMessage = err.response.data ? `${err.response.data.message}.` : defaultMessage;

      Flash(__(flashMessage), 'alert', flashContainer);
    });
};

export const convertToDiscussion = ({ commit }, noteId) =>
  commit(types.CONVERT_TO_DISCUSSION, noteId);

export const removeConvertedDiscussion = ({ commit }, noteId) =>
  commit(types.REMOVE_CONVERTED_DISCUSSION, noteId);

export const fetchDescriptionVersion = (_, { endpoint, startingVersion }) => {
  let requestUrl = endpoint;

  if (startingVersion) {
    requestUrl = mergeUrlParams({ start_version_id: startingVersion }, requestUrl);
  }

  return axios
    .get(requestUrl)
    .then(res => res.data)
    .catch(() => {
      Flash(__('Something went wrong while fetching description changes. Please try again.'));
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
