import { __ } from '~/locale';

export const DISCUSSION_NOTE = 'DiscussionNote';
export const DIFF_NOTE = 'DiffNote';
export const DISCUSSION = 'discussion';
export const NOTE = 'note';
export const SYSTEM_NOTE = 'systemNote';
export const COMMENT = 'comment';
export const OPENED = 'opened';
export const REOPENED = 'reopened';
export const CLOSED = 'closed';
export const MERGED = 'merged';
export const ISSUE_NOTEABLE_TYPE = 'issue';
export const EPIC_NOTEABLE_TYPE = 'epic';
export const MERGE_REQUEST_NOTEABLE_TYPE = 'MergeRequest';
export const UNRESOLVE_NOTE_METHOD_NAME = 'delete';
export const RESOLVE_NOTE_METHOD_NAME = 'post';
export const DESCRIPTION_TYPE = 'changed the description';
export const DISCUSSION_FILTERS_DEFAULT_VALUE = 0;
export const COMMENTS_ONLY_FILTER_VALUE = 1;
export const HISTORY_ONLY_FILTER_VALUE = 2;
export const DISCUSSION_TAB_LABEL = 'show';
export const NOTE_UNDERSCORE = 'note_';
export const TIME_DIFFERENCE_VALUE = 10;
export const ASC = 'asc';
export const DESC = 'desc';

export const DISCUSSION_FETCH_TIMEOUT = 750;

export const NOTEABLE_TYPE_MAPPING = {
  Issue: ISSUE_NOTEABLE_TYPE,
  MergeRequest: MERGE_REQUEST_NOTEABLE_TYPE,
  Epic: EPIC_NOTEABLE_TYPE,
};

export const DISCUSSION_FILTER_TYPES = {
  ALL: 'all',
  COMMENTS: 'comments',
  HISTORY: 'history',
};

export const toggleStateErrorMessage = {
  Epic: {
    [CLOSED]: __('Something went wrong while reopening the epic. Please try again later.'),
    [OPENED]: __('Something went wrong while closing the epic. Please try again later.'),
    [REOPENED]: __('Something went wrong while closing the epic. Please try again later.'),
  },
  MergeRequest: {
    [CLOSED]: __('Something went wrong while reopening the merge request. Please try again later.'),
    [OPENED]: __('Something went wrong while closing the merge request. Please try again later.'),
    [REOPENED]: __('Something went wrong while closing the merge request. Please try again later.'),
  },
};
