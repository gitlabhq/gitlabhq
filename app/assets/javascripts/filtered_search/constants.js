import {
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_REVIEWER,
} from '~/vue_shared/components/filtered_search_bar/constants';

export const USER_TOKEN_TYPES = [
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_REVIEWER,
  'attention',
];

export const DROPDOWN_TYPE = {
  hint: 'hint',
  operator: 'operator',
};

export const FILTER_TYPE = {
  none: 'none',
  any: 'any',
};

export const MAX_HISTORY_SIZE = 5;

export const FILTERED_SEARCH = {
  MERGE_REQUESTS: 'merge_requests',
  ISSUES: 'issues',
};
