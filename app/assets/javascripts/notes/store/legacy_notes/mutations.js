import { isEqual } from 'lodash';
import { STATUS_CLOSED, STATUS_REOPENED } from '~/issues/constants';
import { isInMRPage } from '~/lib/utils/common_utils';
import { uuids } from '~/lib/utils/uuids';
import * as constants from '../../constants';
import * as types from '../../stores/mutation_types';
import * as utils from '../../stores/utils';

export default {
  [types.ADD_NEW_NOTE](data) {
    const note = data.discussion ? data.discussion.notes[0] : data;
    const { discussion_id: discussionId, type } = note;
    const [exists] = this.discussions.filter((n) => n.id === note.discussion_id);
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

      this.discussions.push(discussion);
    }
  },

  [types.ADD_NEW_REPLY_TO_DISCUSSION](note) {
    const discussion = utils.findNoteObjectById(this.discussions, note.discussion_id);
    const existingNote = discussion && utils.findNoteObjectById(discussion.notes, note.id);

    if (discussion && !existingNote) {
      discussion.notes.push(note);
    }
  },

  [types.DELETE_NOTE](note) {
    const noteObj = utils.findNoteObjectById(this.discussions, note.discussion_id);

    if (noteObj.individual_note) {
      this.discussions.splice(this.discussions.indexOf(noteObj), 1);
    } else {
      const comment = utils.findNoteObjectById(noteObj.notes, note.id);
      noteObj.notes.splice(noteObj.notes.indexOf(comment), 1);

      if (!noteObj.notes.length) {
        this.discussions.splice(this.discussions.indexOf(noteObj), 1);
      }
    }
  },

  [types.EXPAND_DISCUSSION]({ discussionId }) {
    const discussion = utils.findNoteObjectById(this.discussions, discussionId);
    Object.assign(discussion, { expanded: true });
  },

  [types.COLLAPSE_DISCUSSION]({ discussionId }) {
    const discussion = utils.findNoteObjectById(this.discussions, discussionId);
    Object.assign(discussion, { expanded: false });
  },

  [types.REMOVE_PLACEHOLDER_NOTES]() {
    const { discussions } = this;

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

  [types.SET_NOTES_DATA](data) {
    Object.assign(this, { notesData: data });
  },

  [types.SET_NOTEABLE_DATA](data) {
    Object.assign(this, { noteableData: data });
  },

  [types.SET_ISSUE_CONFIDENTIAL](data) {
    this.noteableData.confidential = data;
  },

  [types.SET_ISSUABLE_LOCK](locked) {
    this.noteableData.discussion_locked = locked;
  },

  [types.SET_USER_DATA](data) {
    Object.assign(this, { userData: data });
  },

  [types.CLEAR_DISCUSSIONS]() {
    this.discussions = [];
  },

  [types.ADD_OR_UPDATE_DISCUSSIONS](discussionsData) {
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
          const oldDiscussion = this.discussions.find(
            (existingDiscussion) =>
              existingDiscussion.id === discussion.id && existingDiscussion.notes[0].id === n.id,
          );

          if (oldDiscussion) {
            this.discussions.splice(this.discussions.indexOf(oldDiscussion), 1, newDiscussion);
          } else {
            this.discussions.push(newDiscussion);
          }
        });
      } else {
        const oldDiscussion = utils.findNoteObjectById(this.discussions, discussion.id);

        if (oldDiscussion) {
          this.discussions.splice(this.discussions.indexOf(oldDiscussion), 1, {
            ...discussion,
            ...diffData,
            expanded: oldDiscussion.expanded,
          });
        } else {
          this.discussions.push({ ...discussion, ...diffData });
        }
      }
    });
  },

  [types.SET_LAST_FETCHED_AT](fetchedAt) {
    Object.assign(this, { lastFetchedAt: fetchedAt });
  },

  [types.SET_TARGET_NOTE_HASH](hash) {
    Object.assign(this, { targetNoteHash: hash });
  },

  [types.SHOW_PLACEHOLDER_NOTE](data) {
    let notesArr = this.discussions;

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

  [types.TOGGLE_AWARD](data) {
    const { awardName, note } = data;
    const { id, name, username } = this.userData;

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

  [types.TOGGLE_DISCUSSION]({ discussionId, forceExpanded = null }) {
    const discussion = utils.findNoteObjectById(this.discussions, discussionId);
    Object.assign(discussion, {
      expanded: forceExpanded === null ? !discussion.expanded : forceExpanded,
    });
  },

  [types.SET_EXPAND_DISCUSSIONS]({ discussionIds, expanded }) {
    if (discussionIds?.length) {
      discussionIds.forEach((discussionId) => {
        const discussion = utils.findNoteObjectById(this.discussions, discussionId);
        Object.assign(discussion, { expanded });
      });
    }
  },

  [types.SET_EXPAND_ALL_DISCUSSIONS](expanded) {
    this.discussions.forEach((discussion) => {
      Object.assign(discussion, { expanded });
    });
  },

  [types.SET_RESOLVING_DISCUSSION](isResolving) {
    this.isResolvingDiscussion = isResolving;
  },

  [types.UPDATE_NOTE](note) {
    const discussion = utils.findNoteObjectById(this.discussions, note.discussion_id);

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

  [types.APPLY_SUGGESTION]({ noteId, discussionId, suggestionId }) {
    const noteObj = utils.findNoteObjectById(this.discussions, discussionId);
    const comment = utils.findNoteObjectById(noteObj.notes, noteId);

    comment.suggestions = comment.suggestions.map((suggestion) => ({
      ...suggestion,
      applied: suggestion.applied || suggestion.id === suggestionId,
      appliable: false,
    }));
  },

  [types.SET_APPLYING_BATCH_STATE](isApplyingBatch) {
    this.batchSuggestionsInfo.forEach((suggestionInfo) => {
      const { discussionId, noteId, suggestionId } = suggestionInfo;

      const noteObj = utils.findNoteObjectById(this.discussions, discussionId);
      const comment = utils.findNoteObjectById(noteObj.notes, noteId);

      comment.suggestions = comment.suggestions.map((suggestion) => ({
        ...suggestion,
        is_applying_batch: suggestion.id === suggestionId && isApplyingBatch,
      }));
    });
  },

  [types.ADD_SUGGESTION_TO_BATCH]({ noteId, discussionId, suggestionId }) {
    this.batchSuggestionsInfo.push({
      suggestionId,
      noteId,
      discussionId,
    });
  },

  [types.REMOVE_SUGGESTION_FROM_BATCH](id) {
    const index = this.batchSuggestionsInfo.findIndex(({ suggestionId }) => suggestionId === id);
    if (index !== -1) {
      this.batchSuggestionsInfo.splice(index, 1);
    }
  },

  [types.CLEAR_SUGGESTION_BATCH]() {
    this.batchSuggestionsInfo.splice(0, this.batchSuggestionsInfo.length);
  },

  [types.UPDATE_DISCUSSION](noteData) {
    const note = noteData;
    const selectedDiscussion = this.discussions.find((disc) => disc.id === note.id);
    note.expanded = true; // override expand flag to prevent collapse
    Object.assign(selectedDiscussion, { ...note });
  },

  [types.UPDATE_DISCUSSION_POSITION]({ discussionId, position }) {
    const selectedDiscussion = this.discussions.find((disc) => disc.id === discussionId);
    if (selectedDiscussion) Object.assign(selectedDiscussion.position, { ...position });
  },

  [types.CLOSE_ISSUE]() {
    Object.assign(this.noteableData, { state: STATUS_CLOSED });
  },

  [types.REOPEN_ISSUE]() {
    Object.assign(this.noteableData, { state: STATUS_REOPENED });
  },

  [types.TOGGLE_STATE_BUTTON_LOADING](value) {
    Object.assign(this, { isToggleStateButtonLoading: value });
  },

  [types.SET_NOTES_FETCHED_STATE](value) {
    Object.assign(this, { isNotesFetched: value });
  },

  [types.SET_NOTES_LOADING_STATE](value) {
    this.isLoading = value;
  },

  [types.SET_NOTES_FETCHING_STATE](value) {
    this.isFetching = value;
  },

  [types.SET_DISCUSSION_DIFF_LINES]({ discussionId, diffLines }) {
    const discussion = utils.findNoteObjectById(this.discussions, discussionId);

    discussion.truncated_diff_lines = utils.prepareDiffLines(diffLines);
  },

  [types.SET_DISCUSSIONS_SORT]({ direction, persist }) {
    this.discussionSortOrder = direction;
    this.persistSortOrder = persist;
  },

  [types.SET_TIMELINE_VIEW](value) {
    this.isTimelineEnabled = value;
  },

  [types.SET_SELECTED_COMMENT_POSITION](position) {
    this.selectedCommentPosition = position;
  },

  [types.SET_SELECTED_COMMENT_POSITION_HOVER](position) {
    this.selectedCommentPositionHover = position;
  },

  [types.DISABLE_COMMENTS](value) {
    this.commentsDisabled = value;
  },
  [types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS]() {
    this.resolvableDiscussionsCount = this.discussions.filter(
      (discussion) => !discussion.individual_note && discussion.resolvable,
    ).length;
    this.unresolvedDiscussionsCount = this.discussions.filter(
      (discussion) =>
        !discussion.individual_note &&
        discussion.resolvable &&
        discussion.notes.some((note) => note.resolvable && !note.resolved),
    ).length;
  },

  [types.CONVERT_TO_DISCUSSION](discussionId) {
    const convertedDisscussionIds = [...this.convertedDisscussionIds, discussionId];
    Object.assign(this, { convertedDisscussionIds });
  },

  [types.REMOVE_CONVERTED_DISCUSSION](discussionId) {
    const convertedDisscussionIds = [...this.convertedDisscussionIds];

    convertedDisscussionIds.splice(convertedDisscussionIds.indexOf(discussionId), 1);
    Object.assign(this, { convertedDisscussionIds });
  },

  [types.SET_CURRENT_DISCUSSION_ID](discussionId) {
    this.currentDiscussionId = discussionId;
  },

  [types.REQUEST_DESCRIPTION_VERSION]() {
    this.isLoadingDescriptionVersion = true;
  },
  [types.RECEIVE_DESCRIPTION_VERSION]({ descriptionVersion, versionId }) {
    const descriptionVersions = { ...this.descriptionVersions, [versionId]: descriptionVersion };
    Object.assign(this, { descriptionVersions, isLoadingDescriptionVersion: false });
  },
  [types.RECEIVE_DESCRIPTION_VERSION_ERROR]() {
    this.isLoadingDescriptionVersion = false;
  },
  [types.REQUEST_DELETE_DESCRIPTION_VERSION]() {
    this.isLoadingDescriptionVersion = true;
  },
  [types.RECEIVE_DELETE_DESCRIPTION_VERSION](descriptionVersion) {
    this.isLoadingDescriptionVersion = false;
    Object.assign(this.descriptionVersions, descriptionVersion);
  },
  [types.RECEIVE_DELETE_DESCRIPTION_VERSION_ERROR]() {
    this.isLoadingDescriptionVersion = false;
  },
  [types.UPDATE_ASSIGNEES](assignees) {
    this.noteableData.assignees = assignees;
  },
  [types.SET_FETCHING_DISCUSSIONS](value) {
    this.currentlyFetchingDiscussions = value;
  },
  [types.SET_DONE_FETCHING_BATCH_DISCUSSIONS](value) {
    this.doneFetchingBatchDiscussions = value;
  },
  [types.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS](value) {
    this.isPromoteCommentToTimelineEventInProgress = value;
  },
  [types.SET_IS_POLLING_INITIALIZED](value) {
    this.isPollingInitialized = value;
  },
  [types.SET_MERGE_REQUEST_FILTERS](value) {
    this.mergeRequestFilters = value;
  },
};
