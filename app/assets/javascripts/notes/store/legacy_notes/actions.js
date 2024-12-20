import $ from 'jquery';
import Vue from 'vue';
import { debounce } from 'lodash';
import actionCable from '~/actioncable_consumer';
import Api from '~/api';
import { createAlert, VARIANT_INFO } from '~/alert';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import { STATUS_CLOSED, STATUS_REOPENED, TYPE_ISSUE } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { confidentialWidget } from '~/sidebar/components/confidential/sidebar_confidentiality_widget.vue';
import updateIssueLockMutation from '~/sidebar/queries/update_issue_lock.mutation.graphql';
import updateMergeRequestLockMutation from '~/sidebar/queries/update_merge_request_lock.mutation.graphql';
import loadAwardsHandler from '~/awards_handler';
import { isInMRPage } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import sidebarTimeTrackingEventHub from '~/sidebar/event_hub';
import TaskList from '~/task_list';
import mrWidgetEventHub from '~/vue_merge_request_widget/event_hub';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_NOTE } from '~/graphql_shared/constants';
import { useBatchComments } from '~/batch_comments/store';
import notesEventHub from '../../event_hub';

import promoteTimelineEvent from '../../graphql/promote_timeline_event.mutation.graphql';

import * as constants from '../../constants';
import * as types from '../../stores/mutation_types';
import * as utils from '../../stores/utils';

export function updateLockedAttribute({ locked, fullPath }) {
  const { iid, targetType } = this.getNoteableData;

  return utils.gqClient
    .mutate({
      mutation:
        targetType === TYPE_ISSUE ? updateIssueLockMutation : updateMergeRequestLockMutation,
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
        targetType === TYPE_ISSUE
          ? data.issueSetLocked.issue.discussionLocked
          : data.mergeRequestSetLocked.mergeRequest.discussionLocked;

      this[types.SET_ISSUABLE_LOCK](discussionLocked);
    });
}

export function expandDiscussion(data) {
  if (data.discussionId) {
    // tryStore only used for migration, refactor the store to avoid using this helper
    this.tryStore('legacyDiffs').renderFileForDiscussionId(data.discussionId);
  }

  this[types.EXPAND_DISCUSSION](data);
}

export function collapseDiscussion(data) {
  return this[types.COLLAPSE_DISCUSSION](data);
}

export function setNotesData(data) {
  return this[types.SET_NOTES_DATA](data);
}

export function setNoteableData(data) {
  return this[types.SET_NOTEABLE_DATA](data);
}

export function setConfidentiality(data) {
  return this[types.SET_ISSUE_CONFIDENTIAL](data);
}

export function setUserData(data) {
  return this[types.SET_USER_DATA](data);
}

export function setLastFetchedAt(data) {
  return this[types.SET_LAST_FETCHED_AT](data);
}

export function setInitialNotes(discussions) {
  return this[types.ADD_OR_UPDATE_DISCUSSIONS](discussions);
}

export function setTargetNoteHash(data) {
  return this[types.SET_TARGET_NOTE_HASH](data);
}

export function setNotesFetchedState(state) {
  return this[types.SET_NOTES_FETCHED_STATE](state);
}

export function toggleDiscussion(data) {
  return this[types.TOGGLE_DISCUSSION](data);
}

export function toggleAllDiscussions() {
  const expanded = this.allDiscussionsExpanded;
  this[types.SET_EXPAND_ALL_DISCUSSIONS](!expanded);
}

export function fetchDiscussions({ path, filter, persistFilter }) {
  let config =
    filter !== undefined
      ? { params: { notes_filter: filter, persist_filter: persistFilter } }
      : null;

  if (this.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE) {
    config = { params: { notes_filter: 0, persist_filter: false } };
  }

  if (
    this.noteableType === constants.ISSUE_NOTEABLE_TYPE ||
    this.noteableType === constants.MERGE_REQUEST_NOTEABLE_TYPE
  ) {
    return this.fetchDiscussionsBatch({ path, config, perPage: 20 });
  }

  return axios.get(path, config).then(({ data }) => {
    this[types.ADD_OR_UPDATE_DISCUSSIONS](data);
    this[types.SET_FETCHING_DISCUSSIONS](false);

    this.updateResolvableDiscussionsCounts();
  });
}

export function fetchNotes() {
  if (this.isFetching) return null;

  this.setFetchingState(true);

  return this.fetchDiscussions(this.getFetchDiscussionsConfig)
    .then(() => this.initPolling())
    .then(() => {
      this.setLoadingState(false);
      this.setNotesFetchedState(true);
      notesEventHub.$emit('fetchedNotesData');
      this.setFetchingState(false);
    })
    .catch(() => {
      this.setLoadingState(false);
      this.setNotesFetchedState(true);
      createAlert({
        message: __('Something went wrong while fetching comments. Please try again.'),
      });
    });
}

export function initPolling() {
  if (this.isPollingInitialized) {
    return;
  }

  this.setLastFetchedAt(this.getNotesDataByProp('lastFetchedAt'));

  const debouncedFetchUpdatedNotes = debounce(() => {
    this.fetchUpdatedNotes();
  }, constants.FETCH_UPDATED_NOTES_DEBOUNCE_TIMEOUT);

  actionCable.subscriptions.create(
    {
      channel: 'Noteable::NotesChannel',
      project_id: this.notesData.projectId,
      group_id: this.notesData.groupId,
      noteable_type: this.notesData.noteableType,
      noteable_id: this.notesData.noteableId,
    },
    {
      connected() {
        this.fetchUpdatedNotes();
      },
      received(data) {
        if (data.event === 'updated') {
          debouncedFetchUpdatedNotes();
        }
      },
    },
  );

  this[types.SET_IS_POLLING_INITIALIZED](true);
}

export function fetchDiscussionsBatch({ path, config, cursor, perPage }) {
  const params = { ...config?.params, per_page: perPage };

  if (cursor) {
    params.cursor = cursor;
  }

  return axios.get(path, { params }).then(({ data, headers }) => {
    this[types.ADD_OR_UPDATE_DISCUSSIONS](data);

    if (headers && headers['x-next-page-cursor']) {
      const nextConfig = { ...config };

      if (config?.params?.persist_filter) {
        delete nextConfig.params.notes_filter;
        delete nextConfig.params.persist_filter;
      }

      return this.fetchDiscussionsBatch({
        path,
        config: nextConfig,
        cursor: headers['x-next-page-cursor'],
        perPage: Math.min(Math.round(perPage * 1.5), 100),
      });
    }

    this[types.SET_DONE_FETCHING_BATCH_DISCUSSIONS](true);
    this[types.SET_FETCHING_DISCUSSIONS](false);
    this.updateResolvableDiscussionsCounts();

    return undefined;
  });
}

export function updateDiscussion(discussion) {
  if (discussion == null) return null;

  this[types.UPDATE_DISCUSSION](discussion);

  return utils.findNoteObjectById(this.discussions, discussion.id);
}

export function setDiscussionSortDirection({ direction, persist = true }) {
  this[types.SET_DISCUSSIONS_SORT]({ direction, persist });
}

export function setTimelineView(enabled) {
  this[types.SET_TIMELINE_VIEW](enabled);
}

export function setSelectedCommentPosition(position) {
  this[types.SET_SELECTED_COMMENT_POSITION](position);
}

export function setSelectedCommentPositionHover(position) {
  this[types.SET_SELECTED_COMMENT_POSITION_HOVER](position);
}

export function removeNote(note) {
  const discussion = this.discussions.find(({ id }) => id === note.discussion_id);

  this[types.DELETE_NOTE](note);

  this.updateMergeRequestWidget();
  this.updateResolvableDiscussionsCounts();

  if (isInMRPage()) {
    // tryStore only used for migration, refactor the store to avoid using this helper
    this.tryStore('legacyDiffs').removeDiscussionsFromDiff(discussion);
  }
}

export function deleteNote(note) {
  return axios.delete(note.path).then(() => {
    this.removeNote(note);
  });
}

export function updateNote({ endpoint, note }) {
  return axios.put(endpoint, note).then(({ data }) => {
    this[types.UPDATE_NOTE](data);
    this.startTaskList();
  });
}

export function updateOrCreateNotes(notes) {
  const debouncedFetchDiscussions = (isFetching) => {
    if (!isFetching) {
      this[types.SET_FETCHING_DISCUSSIONS](true);
      this.fetchDiscussions({ path: this.notesData.discussionsPath });
    } else {
      if (isFetching !== true) {
        clearTimeout(this.currentlyFetchingDiscussions);
      }

      this[types.SET_FETCHING_DISCUSSIONS](
        setTimeout(() => {
          this.fetchDiscussions({ path: this.notesData.discussionsPath });
        }, constants.DISCUSSION_FETCH_TIMEOUT),
      );
    }
  };

  notes.forEach((note) => {
    if (this.notesById[note.id]) {
      this[types.UPDATE_NOTE](note);
    } else if (note.type === constants.DISCUSSION_NOTE || note.type === constants.DIFF_NOTE) {
      const discussion = utils.findNoteObjectById(this.discussions, note.discussion_id);

      if (discussion) {
        this[types.ADD_NEW_REPLY_TO_DISCUSSION](note);
      } else if (note.type === constants.DIFF_NOTE && !note.base_discussion) {
        debouncedFetchDiscussions(this.currentlyFetchingDiscussions);
      } else {
        this[types.ADD_NEW_NOTE](note);
      }
    } else {
      this[types.ADD_NEW_NOTE](note);
    }
  });
}

export function promoteCommentToTimelineEvent({ noteId, addError, addGenericError }) {
  this[types.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS](true); // Set loading state
  return utils.gqClient
    .mutate({
      mutation: promoteTimelineEvent,
      variables: {
        input: {
          noteId: convertToGraphQLId(TYPENAME_NOTE, noteId),
        },
      },
    })
    .then(({ data = {} }) => {
      const errors = data.timelineEventPromoteFromNote?.errors;
      if (errors.length) {
        const errorMessage = sprintf(addError, {
          error: errors.join('. '),
        });
        throw new Error(errorMessage);
      } else {
        notesEventHub.$emit('comment-promoted-to-timeline-event');
        toast(__('Comment added to the timeline.'));
      }
    })
    .catch((error) => {
      const message = error.message || addGenericError;

      let captureError = false;
      let errorObj = null;

      if (message === addGenericError) {
        captureError = true;
        errorObj = error;
      }

      createAlert({
        message,
        captureError,
        error: errorObj,
      });
    })
    .finally(() => {
      this[types.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS](false); // Revert loading state
    });
}

export function replyToDiscussion({ endpoint, data: reply }) {
  return axios.post(endpoint, reply).then(({ data }) => {
    if (data.discussion) {
      this[types.UPDATE_DISCUSSION](data.discussion);

      this.updateOrCreateNotes(data.discussion.notes);

      this.updateMergeRequestWidget();
      this.startTaskList();
      this.updateResolvableDiscussionsCounts();
    } else {
      this[types.ADD_NEW_REPLY_TO_DISCUSSION](data);
    }

    return data;
  });
}

export function createNewNote({ endpoint, data: reply }) {
  return axios.post(endpoint, reply).then(({ data }) => {
    if (!data.errors) {
      this[types.ADD_NEW_NOTE](data);

      this.updateMergeRequestWidget();
      this.startTaskList();
      this.updateResolvableDiscussionsCounts();
    }
    return data;
  });
}

export function removePlaceholderNotes() {
  return this[types.REMOVE_PLACEHOLDER_NOTES]();
}

export function resolveDiscussion({ discussionId }) {
  const discussion = utils.findNoteObjectById(this.discussions, discussionId);
  const isResolved = this.isDiscussionResolved(discussionId);

  if (!discussion) {
    return Promise.reject();
  }
  if (isResolved) {
    return Promise.resolve();
  }

  return this.toggleResolveNote({
    endpoint: discussion.resolve_path,
    isResolved,
    discussion: true,
  });
}

export function toggleResolveNote({ endpoint, isResolved, discussion }) {
  const method = isResolved
    ? constants.UNRESOLVE_NOTE_METHOD_NAME
    : constants.RESOLVE_NOTE_METHOD_NAME;
  const mutationType = discussion ? types.UPDATE_DISCUSSION : types.UPDATE_NOTE;

  return axios[method](endpoint).then(({ data }) => {
    this[mutationType](data);

    this.updateResolvableDiscussionsCounts();

    this.updateMergeRequestWidget();
  });
}

export function closeIssuable() {
  this.toggleStateButtonLoading(true);
  return axios.put(this.notesData.closePath).then(({ data }) => {
    this[types.CLOSE_ISSUE]();
    this.emitStateChangedEvent(data);
    this.toggleStateButtonLoading(false);
  });
}

export function reopenIssuable() {
  this.toggleStateButtonLoading(true);
  return axios.put(this.notesData.reopenPath).then(({ data }) => {
    this[types.REOPEN_ISSUE]();
    this.emitStateChangedEvent(data);
    this.toggleStateButtonLoading(false);
  });
}

export function toggleStateButtonLoading(value) {
  return this[types.TOGGLE_STATE_BUTTON_LOADING](value);
}

export function emitStateChangedEvent(data) {
  const event = new CustomEvent(EVENT_ISSUABLE_VUE_APP_CHANGE, {
    detail: {
      data,
      isClosed: this.openState === STATUS_CLOSED,
    },
  });

  document.dispatchEvent(event);
}

export function toggleIssueLocalState(newState) {
  if (newState === STATUS_CLOSED) {
    this[types.CLOSE_ISSUE]();
  } else if (newState === STATUS_REOPENED) {
    this[types.REOPEN_ISSUE]();
  }
}

export function saveNote(noteData) {
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
      ? useBatchComments().addDraftToDiscussion
      : useBatchComments().createNewDraft;
    if (!postData.draft_note && noteData.note) {
      postData.draft_note = postData.note;
      delete postData.note;
    }
  } else {
    methodToDispatch = replyId ? this.replyToDiscussion : this.createNewNote;
  }

  this[types.REMOVE_PLACEHOLDER_NOTES](); // remove previous placeholders

  if (hasQuickActions) {
    placeholderText = utils.stripQuickActions(placeholderText);
  }

  if (placeholderText.length) {
    this[types.SHOW_PLACEHOLDER_NOTE]({
      noteBody: placeholderText,
      replyId,
    });
  }

  if (hasQuickActions) {
    this[types.SHOW_PLACEHOLDER_NOTE]({
      isSystemNote: true,
      noteBody: utils.getQuickActionText(note),
      replyId,
    });
  }

  const processQuickActions = (res) => {
    const { quick_actions_status: { messages = null, command_names: commandNames = [] } = {} } =
      res;

    if (commandNames?.indexOf('submit_review') >= 0) {
      useBatchComments().clearDrafts();
    }

    /*
     The following reply means that quick actions have been successfully applied:

     {"commands_changes":{},"valid":false,"errors":{},"quick_actions_status":{"messages":["Commands applied"],"command_names":["due"],"commands_only":true}}
     */
    if (hasQuickActions && messages) {
      // synchronizing the quick action with the sidebar widget
      // this is a temporary solution until we have confidentiality real-time updates
      if (
        confidentialWidget.setConfidentiality &&
        messages.some((m) => m.includes('Made this issue confidential'))
      ) {
        confidentialWidget.setConfidentiality();
      }

      $('.js-gfm-input').trigger('clear-commands-cache.atwho');

      createAlert({
        message: messages || __('Commands applied'),
        variant: VARIANT_INFO,
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
        createAlert({
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
    this[types.REMOVE_PLACEHOLDER_NOTES]();

    return res;
  };

  return methodToDispatch(postData)
    .then(processQuickActions)
    .then(processEmojiAward)
    .then(processTimeTracking)
    .then(removePlaceholder);
}

export function setFetchingState(fetchingState) {
  return this[types.SET_NOTES_FETCHING_STATE](fetchingState);
}

const getFetchDataParams = (state) => {
  const endpoint = state.notesData.notesPath;
  const options = {
    headers: {
      'X-Last-Fetched-At': state.lastFetchedAt ? `${state.lastFetchedAt}` : undefined,
    },
  };

  return { endpoint, options };
};

export function fetchUpdatedNotes() {
  const { endpoint, options } = getFetchDataParams(this);

  return axios
    .get(endpoint, options)
    .then(async ({ data }) => {
      if (this.isResolvingDiscussion) {
        return null;
      }

      if (data.notes?.length) {
        await this.updateOrCreateNotes(data.notes);
        this.startTaskList();
        this.updateResolvableDiscussionsCounts();
      }

      this[types.SET_LAST_FETCHED_AT](data.last_fetched_at);

      return undefined;
    })
    .catch(() => {});
}

export function toggleAward({ awardName, noteId }) {
  this[types.TOGGLE_AWARD]({ awardName, note: this.notesById[noteId] });
}

export function toggleAwardRequest(data) {
  const { endpoint, awardName } = data;

  return axios.post(endpoint, { name: awardName }).then(() => {
    this.toggleAward(data);
  });
}

export function fetchDiscussionDiffLines(discussion) {
  return axios.get(discussion.truncated_diff_lines_path).then(({ data }) => {
    this[types.SET_DISCUSSION_DIFF_LINES]({
      discussionId: discussion.id,
      diffLines: data.truncated_diff_lines,
    });
  });
}

export const updateMergeRequestWidget = () => {
  mrWidgetEventHub.$emit('mr.discussion.updated');
};

export function setLoadingState(data) {
  this[types.SET_NOTES_LOADING_STATE](data);
}

export function filterDiscussion({ path, filter, persistFilter }) {
  this[types.CLEAR_DISCUSSIONS]();
  this.setLoadingState(true);
  this.fetchDiscussions({ path, filter, persistFilter })
    .then(() => {
      this.setLoadingState(false);
      this.setNotesFetchedState(true);
    })
    .catch(() => {
      this.setLoadingState(false);
      this.setNotesFetchedState(true);
      createAlert({
        message: __('Something went wrong while fetching comments. Please try again.'),
      });
    });
}

export function setCommentsDisabled(data) {
  this[types.DISABLE_COMMENTS](data);
}

export function startTaskList() {
  return Vue.nextTick(
    () =>
      new TaskList({
        dataType: 'note',
        fieldName: 'note',
        selector: '.notes .is-editable',
        onSuccess: () => this.startTaskList(),
      }),
  );
}

export function updateResolvableDiscussionsCounts() {
  return this[types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS]();
}

export function submitSuggestion({ discussionId, suggestionId, flashContainer, message }) {
  const dispatchResolveDiscussion = () => this.resolveDiscussion({ discussionId }).catch(() => {});

  this[types.SET_RESOLVING_DISCUSSION](true);

  return Api.applySuggestion(suggestionId, message)
    .then(dispatchResolveDiscussion)
    .catch((err) => {
      const defaultMessage = __(
        'Something went wrong while applying the suggestion. Please try again.',
      );

      const errorMessage = err.response.data?.message;

      const alertMessage = errorMessage || defaultMessage;

      createAlert({
        message: alertMessage,
        parent: flashContainer,
      });
    })
    .finally(() => {
      this[types.SET_RESOLVING_DISCUSSION](false);
    });
}

export function submitSuggestionBatch({ message, flashContainer }) {
  const suggestionIds = this.batchSuggestionsInfo.map(({ suggestionId }) => suggestionId);

  const resolveAllDiscussions = () =>
    this.batchSuggestionsInfo.map((suggestionInfo) => {
      const { discussionId } = suggestionInfo;
      return this.resolveDiscussion({ discussionId }).catch(() => {});
    });

  this[types.SET_APPLYING_BATCH_STATE](true);
  this[types.SET_RESOLVING_DISCUSSION](true);

  return Api.applySuggestionBatch(suggestionIds, message)
    .then(() => Promise.all(resolveAllDiscussions()))
    .then(() => this[types.CLEAR_SUGGESTION_BATCH]())
    .catch((err) => {
      const defaultMessage = __(
        'Something went wrong while applying the batch of suggestions. Please try again.',
      );

      const errorMessage = err.response.data?.message;

      const alertMessage = errorMessage || defaultMessage;

      createAlert({
        message: alertMessage,
        parent: flashContainer,
      });
    })
    .finally(() => {
      this[types.SET_APPLYING_BATCH_STATE](false);
      this[types.SET_RESOLVING_DISCUSSION](false);
    });
}

export function addSuggestionInfoToBatch({ suggestionId, noteId, discussionId }) {
  return this[types.ADD_SUGGESTION_TO_BATCH]({ suggestionId, noteId, discussionId });
}

export function removeSuggestionInfoFromBatch(suggestionId) {
  return this[types.REMOVE_SUGGESTION_FROM_BATCH](suggestionId);
}

export function convertToDiscussion(noteId) {
  return this[types.CONVERT_TO_DISCUSSION](noteId);
}

export function removeConvertedDiscussion(noteId) {
  return this[types.REMOVE_CONVERTED_DISCUSSION](noteId);
}

export function setCurrentDiscussionId(discussionId) {
  return this[types.SET_CURRENT_DISCUSSION_ID](discussionId);
}

export function fetchDescriptionVersion({ endpoint, startingVersion, versionId }) {
  let requestUrl = endpoint;

  if (startingVersion) {
    requestUrl = mergeUrlParams({ start_version_id: startingVersion }, requestUrl);
  }
  this.requestDescriptionVersion();

  return axios
    .get(requestUrl)
    .then((res) => {
      this.receiveDescriptionVersion({ descriptionVersion: res.data, versionId });
    })
    .catch((error) => {
      this.receiveDescriptionVersionError(error);
      createAlert({
        message: __('Something went wrong while fetching description changes. Please try again.'),
      });
    });
}

export function requestDescriptionVersion() {
  this[types.REQUEST_DESCRIPTION_VERSION]();
}
export function receiveDescriptionVersion(descriptionVersion) {
  this[types.RECEIVE_DESCRIPTION_VERSION](descriptionVersion);
}
export function receiveDescriptionVersionError(error) {
  this[types.RECEIVE_DESCRIPTION_VERSION_ERROR](error);
}

export function softDeleteDescriptionVersion({ endpoint, startingVersion, versionId }) {
  let requestUrl = endpoint;

  if (startingVersion) {
    requestUrl = mergeUrlParams({ start_version_id: startingVersion }, requestUrl);
  }
  this.requestDeleteDescriptionVersion();

  return axios
    .delete(requestUrl)
    .then(() => {
      this.receiveDeleteDescriptionVersion(versionId);
    })
    .catch((error) => {
      this.receiveDeleteDescriptionVersionError(error);
      createAlert({
        message: __('Something went wrong while deleting description changes. Please try again.'),
      });

      // Throw an error here because a component like SystemNote -
      //  needs to know if the request failed to reset its internal state.
      throw new Error();
    });
}

export function requestDeleteDescriptionVersion() {
  this[types.REQUEST_DELETE_DESCRIPTION_VERSION]();
}
export function receiveDeleteDescriptionVersion(versionId) {
  this[types.RECEIVE_DELETE_DESCRIPTION_VERSION]({ [versionId]: __('Deleted') });
}
export function receiveDeleteDescriptionVersionError(error) {
  this[types.RECEIVE_DELETE_DESCRIPTION_VERSION_ERROR](error);
}

export function updateAssignees(assignees) {
  this[types.UPDATE_ASSIGNEES](assignees);
}

export function updateDiscussionPosition(updatedPosition) {
  this[types.UPDATE_DISCUSSION_POSITION](updatedPosition);
}

export function updateMergeRequestFilters(newFilters) {
  return this[types.SET_MERGE_REQUEST_FILTERS](newFilters);
}
