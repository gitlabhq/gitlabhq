import { STATUS_CLOSED, STATUS_OPEN, STATUS_REOPENED } from '~/issues/constants';
import { __, s__ } from '~/locale';

export const DISCUSSION_NOTE = 'DiscussionNote';
export const DIFF_NOTE = 'DiffNote';
export const DISCUSSION = 'discussion';
export const NOTE = 'note';
export const SYSTEM_NOTE = 'systemNote';
export const COMMENT = 'comment';
export const ISSUE_NOTEABLE_TYPE = 'Issue';
export const EPIC_NOTEABLE_TYPE = 'Epic';
export const MERGE_REQUEST_NOTEABLE_TYPE = 'MergeRequest';
export const SNIPPET_NOTEABLE_TYPE = 'Snippet';
export const DESIGN_NOTEABLE_TYPE = 'DesignManagement::Design';
export const COMMIT_NOTEABLE_TYPE = 'Commit';
export const INCIDENT_NOTEABLE_TYPE = 'INCIDENT'; // TODO: check if value can be converted to `Incident`
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

export const FETCH_UPDATED_NOTES_DEBOUNCE_TIMEOUT = 750;

export const NOTEABLE_TYPE_MAPPING = {
  Issue: ISSUE_NOTEABLE_TYPE,
  MergeRequest: MERGE_REQUEST_NOTEABLE_TYPE,
  Epic: EPIC_NOTEABLE_TYPE,
  Incident: INCIDENT_NOTEABLE_TYPE,
};

export const DISCUSSION_FILTER_TYPES = {
  ALL: 'all',
  COMMENTS: 'comments',
  HISTORY: 'history',
};

export const toggleStateErrorMessage = {
  Epic: {
    [STATUS_CLOSED]: __('Something went wrong while reopening the epic. Please try again later.'),
    [STATUS_OPEN]: __('Something went wrong while closing the epic. Please try again later.'),
    [STATUS_REOPENED]: __('Something went wrong while closing the epic. Please try again later.'),
  },
  MergeRequest: {
    [STATUS_CLOSED]: __(
      'Something went wrong while reopening the merge request. Please try again later.',
    ),
    [STATUS_OPEN]: __(
      'Something went wrong while closing the merge request. Please try again later.',
    ),
    [STATUS_REOPENED]: __(
      'Something went wrong while closing the merge request. Please try again later.',
    ),
  },
};

export const MR_FILTER_OPTIONS = [
  {
    text: __('Approvals'),
    value: 'approval',
    systemNoteIcons: ['approval', 'unapproval', 'check', 'error'],
  },
  {
    text: __('Assignees & reviewers'),
    value: 'assignees_reviewers',
    noteText: [
      s__('IssuableEvents|requested review from'),
      s__('IssuableEvents|removed review request for'),
      s__('IssuableEvents|assigned to'),
      s__('IssuableEvents|unassigned'),
    ],
  },
  {
    text: __('Comments (from bots)'),
    value: 'bot_comments',
    bot: true,
  },
  {
    text: __('Comments (from users)'),
    value: 'comments',
    noteType: ['DiscussionNote', 'DiffNote'],
    individualNote: true,
    noteText: [s__('IssuableEvents|resolved all threads')],
  },
  {
    text: __('Commits & branches'),
    value: 'commit_branches',
    systemNoteIcons: ['commit', 'fork'],
  },
  {
    text: __('Edits'),
    value: 'edits',
    systemNoteIcons: ['pencil', 'todo-done'],
  },
  {
    text: __('Labels'),
    value: 'labels',
    systemNoteIcons: ['label'],
  },
  {
    text: __('Lock status'),
    value: 'lock_status',
    systemNoteIcons: ['lock', 'lock-open'],
  },
  {
    text: __('Mentions'),
    value: 'mentions',
    systemNoteIcons: ['comment-dots'],
  },
  {
    text: __('Merge request status'),
    value: 'status',
    systemNoteIcons: ['merge-request', 'issue-close', 'issues', 'merge-request-close', 'merge'],
  },
  {
    text: __('Tracking'),
    value: 'tracking',
    noteType: ['MilestoneNote'],
    systemNoteIcons: ['timer'],
  },
];
export const MR_FILTER_TRACKING_OPENED = 'user_clicks_comment_filter_dropdown';
export const MR_FILTER_TRACKING_USER_COMMENTS = 'click_comment_filter_toggle_user_comments_in_mr';
export const MR_FILTER_TRACKING_BOT_COMMENTS = 'click_comment_filter_toggle_bot_comments_in_mr';
