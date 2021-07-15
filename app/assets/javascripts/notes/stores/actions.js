import $ from 'jquery';
import Visibility from 'visibilityjs';
import Vue from 'vue';
import Api from '~/api';
import createFlash from '~/flash';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import { confidentialWidget } from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import updateIssueLockMutation from '~/sidebar/components/lock/mutations/update_issue_lock.mutation.graphql';
import updateMergeRequestLockMutation from '~/sidebar/components/lock/mutations/update_merge_request_lock.mutation.graphql';
import loadAwardsHandler from '../../awards_handler';
import { isInViewport, scrollToElement, isInMRPage } from '../../lib/utils/common_utils';
import Poll from '../../lib/utils/poll';
import { create } from '../../lib/utils/recurrence';
import { mergeUrlParams } from '../../lib/utils/url_utility';
import sidebarTimeTrackingEventHub from '../../sidebar/event_hub';
import TaskList from '../../task_list';
import mrWidgetEventHub from '../../vue_merge_request_widget/event_hub';
import * as constants from '../constants';
import eventHub from '../event_hub';
import * as types from './mutation_types';
import * as utils from './utils';

const NOTES_POLLING_INTERVAL = 6000;
let eTagPoll;

export const updateLockedAttribute = ({ commit, getters }, { locked, fullPath }) => {
  const { iid, targetType } = getters.getNoteableData;

  return utils.gqClient
    .mutate({
      mutation: targetType === 'issue' ? updateIssueLockMutation : updateMergeRequestLockMutation,
      variables: {
        input: {
          projectPath: fullPath,
          iid: String(iid),
          locked,
        },
      },
    })
    .then(({ data }) => {
      const discussionLocked =
        targetType === 'issue'
          ? data.issueSetLocked.issue.discussionLocked
          : data.mergeRequestSetLocked.mergeRequest.discussionLocked;

      commit(types.SET_ISSUABLE_LOCK, discussionLocked);
    });
};

export const expandDiscussion = ({ commit, dispatch }, data) => {
  if (data.discussionId) {
    dispatch('diffs/renderFileForDiscussionId', data.discussionId, { root: true });
  }

  commit(types.EXPAND_DISCUSSION, data);
};

export const collapseDiscussion = ({ commit }, data) => commit(types.COLLAPSE_DISCUSSION, data);

export const setNotesData = ({ commit }, data) => commit(types.SET_NOTES_DATA, data);

export const setNoteableData = ({ commit }, data) => commit(types.SET_NOTEABLE_DATA, data);

export const setConfidentiality = ({ commit }, data) => commit(types.SET_ISSUE_CONFIDENTIAL, data);

export const setUserData = ({ commit }, data) => commit(types.SET_USER_DATA, data);

export const setLastFetchedAt = ({ commit }, data) => commit(types.SET_LAST_FETCHED_AT, data);

export const setInitialNotes = ({ commit }, discussions) =>
  commit(types.SET_INITIAL_DISCUSSIONS, discussions);

export const setTargetNoteHash = ({ commit }, data) => commit(types.SET_TARGET_NOTE_HASH, data);

export const setNotesFetchedState = ({ commit }, state) =>
  commit(types.SET_NOTES_FETCHED_STATE, state);

export const toggleDiscussion = ({ commit }, data) => commit(types.TOGGLE_DISCUSSION, data);

export const setExpandDiscussions = ({ commit }, { discussionIds, expanded }) => {
  commit(types.SET_EXPAND_DISCUSSIONS, { discussionIds, expanded });
};

export const fetchDiscussions = ({ commit, dispatch }, { path, filter, persistFilter }) => {
  const config =
    filter !== undefined
      ? { params: { notes_filter: filter, persist_filter: persistFilter } }
      : null;

  return axios.get(path, config).then(({ data }) => {
    commit(types.SET_INITIAL_DISCUSSIONS, data);
    commit(types.SET_FETCHING_DISCUSSIONS, false);

    dispatch('updateResolvableDiscussionsCounts');
  });
};

export const updateDiscussion = ({ commit, state }, discussion) => {
  commit(types.UPDATE_DISCUSSION, discussion);

  return utils.findNoteObjectById(state.discussions, discussion.id);
};

export const setDiscussionSortDirection = ({ commit }, { direction, persist = true }) => {
  commit(types.SET_DISCUSSIONS_SORT, { direction, persist });
};

export const setTimelineView = ({ commit }, enabled) => {
  commit(types.SET_TIMELINE_VIEW, enabled);
};

export const setSelectedCommentPosition = ({ commit }, position) => {
  commit(types.SET_SELECTED_COMMENT_POSITION, position);
};

export const setSelectedCommentPositionHover = ({ commit }, position) => {
  commit(types.SET_SELECTED_COMMENT_POSITION_HOVER, position);
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
  axios.put(endpoint, note).then(({ data }) => {
    commit(types.UPDATE_NOTE, data);
    dispatch('startTaskList');
  });

export const updateOrCreateNotes = ({ commit, state, getters, dispatch }, notes) => {
  const { notesById } = getters;
  const debouncedFetchDiscussions = (isFetching) => {
    if (!isFetching) {
      commit(types.SET_FETCHING_DISCUSSIONS, true);
      dispatch('fetchDiscussions', { path: state.notesData.discussionsPath });
    } else {
      if (isFetching !== true) {
        clearTimeout(state.currentlyFetchingDiscussions);
      }

      commit(
        types.SET_FETCHING_DISCUSSIONS,
        setTimeout(() => {
          dispatch('fetchDiscussions', { path: state.notesData.discussionsPath });
        }, constants.DISCUSSION_FETCH_TIMEOUT),
      );
    }
  };

  notes.forEach((note) => {
    if (notesById[note.id]) {
      commit(types.UPDATE_NOTE, note);
    } else if (note.type === constants.DISCUSSION_NOTE || note.type === constants.DIFF_NOTE) {
      const discussion = utils.findNoteObjectById(state.discussions, note.discussion_id);

      if (discussion) {
        commit(types.ADD_NEW_REPLY_TO_DISCUSSION, note);
      } else if (note.type === constants.DIFF_NOTE && !note.base_discussion) {
        debouncedFetchDiscussions(state.currentlyFetchingDiscussions);
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
  axios.post(endpoint, reply).then(({ data }) => {
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
  axios.post(endpoint, reply).then(({ data }) => {
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

export const toggleResolveNote = ({ commit, dispatch }, { endpoint, isResolved, discussion }) => {
  const method = isResolved
    ? constants.UNRESOLVE_NOTE_METHOD_NAME
    : constants.RESOLVE_NOTE_METHOD_NAME;
  const mutationType = discussion ? types.UPDATE_DISCUSSION : types.UPDATE_NOTE;

  return axios[method](endpoint).then(({ data }) => {
    commit(mutationType, data);

    dispatch('updateResolvableDiscussionsCounts');

    dispatch('updateMergeRequestWidget');
  });
};

export const closeIssuable = ({ commit, dispatch, state }) => {
  dispatch('toggleStateButtonLoading', true);
  return axios.put(state.notesData.closePath).then(({ data }) => {
    commit(types.CLOSE_ISSUE);
    dispatch('emitStateChangedEvent', data);
    dispatch('toggleStateButtonLoading', false);
  });
};

export const reopenIssuable = ({ commit, dispatch, state }) => {
  dispatch('toggleStateButtonLoading', true);
  return axios.put(state.notesData.reopenPath).then(({ data }) => {
    commit(types.REOPEN_ISSUE);
    dispatch('emitStateChangedEvent', data);
    dispatch('toggleStateButtonLoading', false);
  });
};

export const toggleStateButtonLoading = ({ commit }, value) =>
  commit(types.TOGGLE_STATE_BUTTON_LOADING, value);

export const emitStateChangedEvent = ({ getters }, data) => {
  const event = new CustomEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, {
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
  const postData = { ...noteData };
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

  const processQuickActions = (res) => {
    const { errors: { commands_only: message } = { commands_only: null } } = res;
    /*
     The following reply means that quick actions have been successfully applied:

     {"commands_changes":{},"valid":false,"errors":{"commands_only":["Commands applied"]}}
     */
    if (hasQuickActions && message) {
      eTagPoll.makeRequest();

      // synchronizing the quick action with the sidebar widget
      // this is a temporary solution until we have confidentiality real-time updates
      if (
        confidentialWidget.setConfidentiality &&
        message.some((m) => m.includes('Made this issue confidential'))
      ) {
        confidentialWidget.setConfidentiality();
      }

      $('.js-gfm-input').trigger('clear-commands-cache.atwho');

      createFlash({
        message: message || __('Commands applied'),
        type: 'notice',
        parent: noteData.flashContainer,
      });
    }

    return res;
  };

  const processEmojiAward = (res) => {
    const { commands_changes: commandsChanges } = res;
    const { emoji_award: emojiAward } = commandsChanges || {};
    if (!emojiAward) {
      return res;
    }

    const votesBlock = $('.js-awards-block').eq(0);

    return loadAwardsHandler()
      .then((awardsHandler) => {
        awardsHandler.addAwardToEmojiBar(votesBlock, emojiAward);
        awardsHandler.scrollToAwards();
      })
      .catch(() => {
        createFlash({
          message: __('Something went wrong while adding your award. Please try again.'),
          parent: noteData.flashContainer,
        });
      })
      .then(() => res);
  };

  const processTimeTracking = (res) => {
    const { commands_changes: commandsChanges } = res;
    const { spend_time: spendTime, time_estimate: timeEstimate } = commandsChanges || {};
    if (spendTime != null || timeEstimate != null) {
      sidebarTimeTrackingEventHub.$emit('timeTrackingUpdated', {
        commands_changes: commandsChanges,
      });
    }

    return res;
  };

  const removePlaceholder = (res) => {
    commit(types.REMOVE_PLACEHOLDER_NOTES);

    return res;
  };

  const processErrors = (error) => {
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
        createFlash({
          message: errorMsg,
          parent: noteData.flashContainer,
        });
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

export const setFetchingState = ({ commit }, fetchingState) =>
  commit(types.SET_NOTES_FETCHING_STATE, fetchingState);

const pollSuccessCallBack = async (resp, commit, state, getters, dispatch) => {
  if (state.isResolvingDiscussion) {
    return null;
  }

  if (window.gon?.features?.paginatedNotes && !resp.more && state.isFetching) {
    eventHub.$emit('fetchedNotesData');
    dispatch('setFetchingState', false);
    dispatch('setNotesFetchedState', true);
    dispatch('setLoadingState', false);
  }

  if (resp.notes?.length) {
    await dispatch('updateOrCreateNotes', resp.notes);
    dispatch('startTaskList');
    dispatch('updateResolvableDiscussionsCounts');
  }

  commit(types.SET_LAST_FETCHED_AT, resp.last_fetched_at);

  return resp;
};

const getFetchDataParams = (state) => {
  const endpoint = state.notesData.notesPath;
  const options = {
    headers: {
      'X-Last-Fetched-At': state.lastFetchedAt ? `${state.lastFetchedAt}` : undefined,
    },
  };

  return { endpoint, options };
};

export const poll = ({ commit, state, getters, dispatch }) => {
  const notePollOccurrenceTracking = create();
  let flashContainer;

  notePollOccurrenceTracking.handle(1, () => {
    // Since polling halts internally after 1 failure, we manually try one more time
    setTimeout(() => eTagPoll.restart(), NOTES_POLLING_INTERVAL);
  });
  notePollOccurrenceTracking.handle(2, () => {
    // On the second failure in a row, show the alert and try one more time (hoping to succeed and clear the error)
    flashContainer = createFlash({
      message: __('Something went wrong while fetching latest comments.'),
    });
    setTimeout(() => eTagPoll.restart(), NOTES_POLLING_INTERVAL);
  });

  eTagPoll = new Poll({
    resource: {
      poll: () => {
        const { endpoint, options } = getFetchDataParams(state);
        return axios.get(endpoint, options);
      },
    },
    method: 'poll',
    successCallback: ({ data }) => {
      pollSuccessCallBack(data, commit, state, getters, dispatch);

      if (notePollOccurrenceTracking.count) {
        notePollOccurrenceTracking.reset();
      }
      flashContainer?.close();
    },
    errorCallback: () => notePollOccurrenceTracking.occur(),
  });

  if (!Visibility.hidden()) {
    eTagPoll.makeDelayedRequest(2500);
  } else {
    eTagPoll.makeRequest();
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
      createFlash({
        message: __('Something went wrong while fetching comments. Please try again.'),
      });
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
  { discussionId, suggestionId, flashContainer, message },
) => {
  const dispatchResolveDiscussion = () =>
    dispatch('resolveDiscussion', { discussionId }).catch(() => {});

  commit(types.SET_RESOLVING_DISCUSSION, true);
  dispatch('stopPolling');

  return Api.applySuggestion(suggestionId, message)
    .then(dispatchResolveDiscussion)
    .catch((err) => {
      const defaultMessage = __(
        'Something went wrong while applying the suggestion. Please try again.',
      );

      const errorMessage = err.response.data?.message;

      const flashMessage = errorMessage || defaultMessage;

      createFlash({
        message: __(flashMessage),
        parent: flashContainer,
      });
    })
    .finally(() => {
      commit(types.SET_RESOLVING_DISCUSSION, false);
      dispatch('restartPolling');
    });
};

export const submitSuggestionBatch = ({ commit, dispatch, state }, { flashContainer }) => {
  const suggestionIds = state.batchSuggestionsInfo.map(({ suggestionId }) => suggestionId);

  const resolveAllDiscussions = () =>
    state.batchSuggestionsInfo.map((suggestionInfo) => {
      const { discussionId } = suggestionInfo;
      return dispatch('resolveDiscussion', { discussionId }).catch(() => {});
    });

  commit(types.SET_APPLYING_BATCH_STATE, true);
  commit(types.SET_RESOLVING_DISCUSSION, true);
  dispatch('stopPolling');

  return Api.applySuggestionBatch(suggestionIds)
    .then(() => Promise.all(resolveAllDiscussions()))
    .then(() => commit(types.CLEAR_SUGGESTION_BATCH))
    .catch((err) => {
      const defaultMessage = __(
        'Something went wrong while applying the batch of suggestions. Please try again.',
      );

      const errorMessage = err.response.data?.message;

      const flashMessage = errorMessage || defaultMessage;

      createFlash({
        message: __(flashMessage),
        parent: flashContainer,
      });
    })
    .finally(() => {
      commit(types.SET_APPLYING_BATCH_STATE, false);
      commit(types.SET_RESOLVING_DISCUSSION, false);
      dispatch('restartPolling');
    });
};

export const addSuggestionInfoToBatch = ({ commit }, { suggestionId, noteId, discussionId }) =>
  commit(types.ADD_SUGGESTION_TO_BATCH, { suggestionId, noteId, discussionId });

export const removeSuggestionInfoFromBatch = ({ commit }, suggestionId) =>
  commit(types.REMOVE_SUGGESTION_FROM_BATCH, suggestionId);

export const convertToDiscussion = ({ commit }, noteId) =>
  commit(types.CONVERT_TO_DISCUSSION, noteId);

export const removeConvertedDiscussion = ({ commit }, noteId) =>
  commit(types.REMOVE_CONVERTED_DISCUSSION, noteId);

export const setCurrentDiscussionId = ({ commit }, discussionId) =>
  commit(types.SET_CURRENT_DISCUSSION_ID, discussionId);

export const fetchDescriptionVersion = ({ dispatch }, { endpoint, startingVersion, versionId }) => {
  let requestUrl = endpoint;

  if (startingVersion) {
    requestUrl = mergeUrlParams({ start_version_id: startingVersion }, requestUrl);
  }
  dispatch('requestDescriptionVersion');

  return axios
    .get(requestUrl)
    .then((res) => {
      dispatch('receiveDescriptionVersion', { descriptionVersion: res.data, versionId });
    })
    .catch((error) => {
      dispatch('receiveDescriptionVersionError', error);
      createFlash({
        message: __('Something went wrong while fetching description changes. Please try again.'),
      });
    });
};

export const requestDescriptionVersion = ({ commit }) => {
  commit(types.REQUEST_DESCRIPTION_VERSION);
};
export const receiveDescriptionVersion = ({ commit }, descriptionVersion) => {
  commit(types.RECEIVE_DESCRIPTION_VERSION, descriptionVersion);
};
export const receiveDescriptionVersionError = ({ commit }, error) => {
  commit(types.RECEIVE_DESCRIPTION_VERSION_ERROR, error);
};

export const softDeleteDescriptionVersion = (
  { dispatch },
  { endpoint, startingVersion, versionId },
) => {
  let requestUrl = endpoint;

  if (startingVersion) {
    requestUrl = mergeUrlParams({ start_version_id: startingVersion }, requestUrl);
  }
  dispatch('requestDeleteDescriptionVersion');

  return axios
    .delete(requestUrl)
    .then(() => {
      dispatch('receiveDeleteDescriptionVersion', versionId);
    })
    .catch((error) => {
      dispatch('receiveDeleteDescriptionVersionError', error);
      createFlash({
        message: __('Something went wrong while deleting description changes. Please try again.'),
      });

      // Throw an error here because a component like SystemNote -
      //  needs to know if the request failed to reset its internal state.
      throw new Error();
    });
};

export const requestDeleteDescriptionVersion = ({ commit }) => {
  commit(types.REQUEST_DELETE_DESCRIPTION_VERSION);
};
export const receiveDeleteDescriptionVersion = ({ commit }, versionId) => {
  commit(types.RECEIVE_DELETE_DESCRIPTION_VERSION, { [versionId]: __('Deleted') });
};
export const receiveDeleteDescriptionVersionError = ({ commit }, error) => {
  commit(types.RECEIVE_DELETE_DESCRIPTION_VERSION_ERROR, error);
};

export const updateAssignees = ({ commit }, assignees) => {
  commit(types.UPDATE_ASSIGNEES, assignees);
};

export const updateDiscussionPosition = ({ commit }, updatedPosition) => {
  commit(types.UPDATE_DISCUSSION_POSITION, updatedPosition);
};
