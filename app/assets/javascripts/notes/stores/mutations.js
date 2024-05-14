import { isEqual } from 'lodash';
import { STATUS_CLOSED, STATUS_REOPENED } from '~/issues/constants';
import { isInMRPage } from '~/lib/utils/common_utils';
import { uuids } from '~/lib/utils/uuids';
import * as constants from '../constants';
import * as types from './mutation_types';
import * as utils from './utils';

export default {
  [types.ADD_NEW_NOTE](state, data) {
    const note = data.discussion ? data.discussion.notes[0] : data;
    const { discussion_id: discussionId, type } = note;
    const [exists] = state.discussions.filter((n) => n.id === note.discussion_id);
    const isDiscussion = type === constants.DISCUSSION_NOTE || type === constants.DIFF_NOTE;

    if (!exists) {
      let discussion = data.discussion || note.base_discussion;

      if (!discussion) {
        discussion = {
          expanded: true,
          id: discussionId,
          individual_note: !isDiscussion,
          reply_id: discussionId,
        };

        if (isDiscussion && isInMRPage()) {
          discussion.resolvable = note.resolvable;
          discussion.resolved = false;
          discussion.active = true;
          discussion.resolve_path = note.resolve_path;
          discussion.resolve_with_issue_path = note.resolve_with_issue_path;
          discussion.diff_discussion = false;
        }
      }

      if (discussion.truncated_diff_lines) {
        discussion.truncated_diff_lines = utils.prepareDiffLines(discussion.truncated_diff_lines);
      }

      // note.base_discussion = undefined; // No point keeping a reference to this
      delete note.base_discussion;
      discussion.notes = [note];

      state.discussions.push(discussion);
    }
  },

  [types.ADD_NEW_REPLY_TO_DISCUSSION](state, note) {
    const discussion = utils.findNoteObjectById(state.discussions, note.discussion_id);
    const existingNote = discussion && utils.findNoteObjectById(discussion.notes, note.id);

    if (discussion && !existingNote) {
      discussion.notes.push(note);
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
    Object.assign(discussion, { expanded: true });
  },

  [types.COLLAPSE_DISCUSSION](state, { discussionId }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);
    Object.assign(discussion, { expanded: false });
  },

  [types.REMOVE_PLACEHOLDER_NOTES](state) {
    const { discussions } = state;

    for (let i = discussions.length - 1; i >= 0; i -= 1) {
      const note = discussions[i];
      const children = note.notes;

      if (children.length > 1) {
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

  [types.SET_ISSUE_CONFIDENTIAL](state, data) {
    state.noteableData.confidential = data;
  },

  [types.SET_ISSUABLE_LOCK](state, locked) {
    state.noteableData.discussion_locked = locked;
  },

  [types.SET_USER_DATA](state, data) {
    Object.assign(state, { userData: data });
  },

  [types.CLEAR_DISCUSSIONS](state) {
    state.discussions = [];
  },

  [types.ADD_OR_UPDATE_DISCUSSIONS](state, discussionsData) {
    discussionsData.forEach((d) => {
      const discussion = { ...d };
      const diffData = {};

      if (discussion.diff_file) {
        diffData.file_hash = discussion.diff_file.file_hash;

        diffData.truncated_diff_lines = utils.prepareDiffLines(
          discussion.truncated_diff_lines || [],
        );
      }

      // To support legacy notes, should be very rare case.
      if (discussion.individual_note && discussion.notes.length > 1) {
        discussion.notes.forEach((n) => {
          const newDiscussion = {
            ...discussion,
            ...diffData,
            notes: [n], // override notes array to only have one item to mimick individual_note
          };
          const oldDiscussion = state.discussions.find(
            (existingDiscussion) =>
              existingDiscussion.id === discussion.id && existingDiscussion.notes[0].id === n.id,
          );

          if (oldDiscussion) {
            state.discussions.splice(state.discussions.indexOf(oldDiscussion), 1, newDiscussion);
          } else {
            state.discussions.push(newDiscussion);
          }
        });
      } else {
        const oldDiscussion = utils.findNoteObjectById(state.discussions, discussion.id);

        if (oldDiscussion) {
          state.discussions.splice(state.discussions.indexOf(oldDiscussion), 1, {
            ...discussion,
            ...diffData,
            expanded: oldDiscussion.expanded,
          });
        } else {
          state.discussions.push({ ...discussion, ...diffData });
        }
      }
    });
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
      id: uuids()[0],
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
      (emoji) => `${emoji.name}` === `${data.awardName}` && emoji.user.id === id,
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

  [types.TOGGLE_DISCUSSION](state, { discussionId, forceExpanded = null }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);
    Object.assign(discussion, {
      expanded: forceExpanded === null ? !discussion.expanded : forceExpanded,
    });
  },

  [types.SET_EXPAND_DISCUSSIONS](state, { discussionIds, expanded }) {
    if (discussionIds?.length) {
      discussionIds.forEach((discussionId) => {
        const discussion = utils.findNoteObjectById(state.discussions, discussionId);
        Object.assign(discussion, { expanded });
      });
    }
  },

  [types.SET_EXPAND_ALL_DISCUSSIONS](state, expanded) {
    state.discussions.forEach((discussion) => {
      Object.assign(discussion, { expanded });
    });
  },

  [types.SET_RESOLVING_DISCUSSION](state, isResolving) {
    state.isResolvingDiscussion = isResolving;
  },

  [types.UPDATE_NOTE](state, note) {
    const discussion = utils.findNoteObjectById(state.discussions, note.discussion_id);

    // Disable eslint here so we can delete the property that we no longer need
    // in the note object
    // eslint-disable-next-line no-param-reassign
    delete note.base_discussion;

    if (discussion.individual_note) {
      if (note.type === constants.DISCUSSION_NOTE) {
        discussion.individual_note = false;
      }

      discussion.notes.splice(0, 1, note);
    } else {
      const comment = utils.findNoteObjectById(discussion.notes, note.id);

      if (!isEqual(comment, note)) {
        discussion.notes.splice(discussion.notes.indexOf(comment), 1, note);
      }
    }

    if (note.resolvable && note.id === discussion.notes[0].id) {
      Object.assign(discussion, {
        resolvable: note.resolvable,
        resolved: note.resolved,
        resolved_at: note.resolved_at,
        resolved_by: note.resolved_by,
        resolved_by_push: note.resolved_by_push,
      });
    }
  },

  [types.APPLY_SUGGESTION](state, { noteId, discussionId, suggestionId }) {
    const noteObj = utils.findNoteObjectById(state.discussions, discussionId);
    const comment = utils.findNoteObjectById(noteObj.notes, noteId);

    comment.suggestions = comment.suggestions.map((suggestion) => ({
      ...suggestion,
      applied: suggestion.applied || suggestion.id === suggestionId,
      appliable: false,
    }));
  },

  [types.SET_APPLYING_BATCH_STATE](state, isApplyingBatch) {
    state.batchSuggestionsInfo.forEach((suggestionInfo) => {
      const { discussionId, noteId, suggestionId } = suggestionInfo;

      const noteObj = utils.findNoteObjectById(state.discussions, discussionId);
      const comment = utils.findNoteObjectById(noteObj.notes, noteId);

      comment.suggestions = comment.suggestions.map((suggestion) => ({
        ...suggestion,
        is_applying_batch: suggestion.id === suggestionId && isApplyingBatch,
      }));
    });
  },

  [types.ADD_SUGGESTION_TO_BATCH](state, { noteId, discussionId, suggestionId }) {
    state.batchSuggestionsInfo.push({
      suggestionId,
      noteId,
      discussionId,
    });
  },

  [types.REMOVE_SUGGESTION_FROM_BATCH](state, id) {
    const index = state.batchSuggestionsInfo.findIndex(({ suggestionId }) => suggestionId === id);
    if (index !== -1) {
      state.batchSuggestionsInfo.splice(index, 1);
    }
  },

  [types.CLEAR_SUGGESTION_BATCH](state) {
    state.batchSuggestionsInfo.splice(0, state.batchSuggestionsInfo.length);
  },

  [types.UPDATE_DISCUSSION](state, noteData) {
    const note = noteData;
    const selectedDiscussion = state.discussions.find((disc) => disc.id === note.id);
    note.expanded = true; // override expand flag to prevent collapse
    Object.assign(selectedDiscussion, { ...note });
  },

  [types.UPDATE_DISCUSSION_POSITION](state, { discussionId, position }) {
    const selectedDiscussion = state.discussions.find((disc) => disc.id === discussionId);
    if (selectedDiscussion) Object.assign(selectedDiscussion.position, { ...position });
  },

  [types.CLOSE_ISSUE](state) {
    Object.assign(state.noteableData, { state: STATUS_CLOSED });
  },

  [types.REOPEN_ISSUE](state) {
    Object.assign(state.noteableData, { state: STATUS_REOPENED });
  },

  [types.TOGGLE_STATE_BUTTON_LOADING](state, value) {
    Object.assign(state, { isToggleStateButtonLoading: value });
  },

  [types.SET_NOTES_FETCHED_STATE](state, value) {
    Object.assign(state, { isNotesFetched: value });
  },

  [types.SET_NOTES_LOADING_STATE](state, value) {
    state.isLoading = value;
  },

  [types.SET_NOTES_FETCHING_STATE](state, value) {
    state.isFetching = value;
  },

  [types.SET_DISCUSSION_DIFF_LINES](state, { discussionId, diffLines }) {
    const discussion = utils.findNoteObjectById(state.discussions, discussionId);

    discussion.truncated_diff_lines = utils.prepareDiffLines(diffLines);
  },

  [types.SET_DISCUSSIONS_SORT](state, { direction, persist }) {
    state.discussionSortOrder = direction;
    state.persistSortOrder = persist;
  },

  [types.SET_TIMELINE_VIEW](state, value) {
    state.isTimelineEnabled = value;
  },

  [types.SET_SELECTED_COMMENT_POSITION](state, position) {
    state.selectedCommentPosition = position;
  },

  [types.SET_SELECTED_COMMENT_POSITION_HOVER](state, position) {
    state.selectedCommentPositionHover = position;
  },

  [types.DISABLE_COMMENTS](state, value) {
    state.commentsDisabled = value;
  },
  [types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS](state) {
    state.resolvableDiscussionsCount = state.discussions.filter(
      (discussion) => !discussion.individual_note && discussion.resolvable,
    ).length;
    state.unresolvedDiscussionsCount = state.discussions.filter(
      (discussion) =>
        !discussion.individual_note &&
        discussion.resolvable &&
        discussion.notes.some((note) => note.resolvable && !note.resolved),
    ).length;
  },

  [types.CONVERT_TO_DISCUSSION](state, discussionId) {
    const convertedDisscussionIds = [...state.convertedDisscussionIds, discussionId];
    Object.assign(state, { convertedDisscussionIds });
  },

  [types.REMOVE_CONVERTED_DISCUSSION](state, discussionId) {
    const convertedDisscussionIds = [...state.convertedDisscussionIds];

    convertedDisscussionIds.splice(convertedDisscussionIds.indexOf(discussionId), 1);
    Object.assign(state, { convertedDisscussionIds });
  },

  [types.SET_CURRENT_DISCUSSION_ID](state, discussionId) {
    state.currentDiscussionId = discussionId;
  },

  [types.REQUEST_DESCRIPTION_VERSION](state) {
    state.isLoadingDescriptionVersion = true;
  },
  [types.RECEIVE_DESCRIPTION_VERSION](state, { descriptionVersion, versionId }) {
    const descriptionVersions = { ...state.descriptionVersions, [versionId]: descriptionVersion };
    Object.assign(state, { descriptionVersions, isLoadingDescriptionVersion: false });
  },
  [types.RECEIVE_DESCRIPTION_VERSION_ERROR](state) {
    state.isLoadingDescriptionVersion = false;
  },
  [types.REQUEST_DELETE_DESCRIPTION_VERSION](state) {
    state.isLoadingDescriptionVersion = true;
  },
  [types.RECEIVE_DELETE_DESCRIPTION_VERSION](state, descriptionVersion) {
    state.isLoadingDescriptionVersion = false;
    Object.assign(state.descriptionVersions, descriptionVersion);
  },
  [types.RECEIVE_DELETE_DESCRIPTION_VERSION_ERROR](state) {
    state.isLoadingDescriptionVersion = false;
  },
  [types.UPDATE_ASSIGNEES](state, assignees) {
    state.noteableData.assignees = assignees;
  },
  [types.SET_FETCHING_DISCUSSIONS](state, value) {
    state.currentlyFetchingDiscussions = value;
  },
  [types.SET_DONE_FETCHING_BATCH_DISCUSSIONS](state, value) {
    state.doneFetchingBatchDiscussions = value;
  },
  [types.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS](state, value) {
    state.isPromoteCommentToTimelineEventInProgress = value;
  },
  [types.SET_IS_POLLING_INITIALIZED](state, value) {
    state.isPollingInitialized = value;
  },
  [types.SET_MERGE_REQUEST_FILTERS](state, value) {
    state.mergeRequestFilters = value;
  },
};
