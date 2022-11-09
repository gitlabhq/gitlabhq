import { __, s__ } from '~/locale';

export const DEBOUNCE_DELAY = 500;
export const MAX_RECENT_TOKENS_SIZE = 3;

export const FILTER_NONE = 'None';
export const FILTER_ANY = 'Any';
export const FILTER_CURRENT = 'Current';
export const FILTER_UPCOMING = 'Upcoming';
export const FILTER_STARTED = 'Started';
export const FILTER_NONE_ANY = [FILTER_NONE, FILTER_ANY];

export const OPERATOR_IS = '=';
export const OPERATOR_IS_TEXT = __('is');
export const OPERATOR_IS_NOT = '!=';
export const OPERATOR_IS_NOT_TEXT = __('is not');

export const OPERATOR_IS_ONLY = [{ value: OPERATOR_IS, description: OPERATOR_IS_TEXT }];
export const OPERATOR_IS_NOT_ONLY = [{ value: OPERATOR_IS_NOT, description: OPERATOR_IS_NOT_TEXT }];
export const OPERATOR_IS_AND_IS_NOT = [...OPERATOR_IS_ONLY, ...OPERATOR_IS_NOT_ONLY];

export const DEFAULT_LABEL_NONE = { value: FILTER_NONE, text: __('None'), title: __('None') };
export const DEFAULT_LABEL_ANY = { value: FILTER_ANY, text: __('Any'), title: __('Any') };
export const DEFAULT_NONE_ANY = [DEFAULT_LABEL_NONE, DEFAULT_LABEL_ANY];

export const DEFAULT_MILESTONE_UPCOMING = {
  value: FILTER_UPCOMING,
  text: __('Upcoming'),
  title: __('Upcoming'),
};
export const DEFAULT_MILESTONE_STARTED = {
  value: FILTER_STARTED,
  text: __('Started'),
  title: __('Started'),
};
export const DEFAULT_MILESTONES = DEFAULT_NONE_ANY.concat([
  DEFAULT_MILESTONE_UPCOMING,
  DEFAULT_MILESTONE_STARTED,
]);

export const SortDirection = {
  descending: 'descending',
  ascending: 'ascending',
};

export const FILTERED_SEARCH_LABELS = 'labels';
export const FILTERED_SEARCH_TERM = 'filtered-search-term';

export const TOKEN_TITLE_ASSIGNEE = s__('SearchToken|Assignee');
export const TOKEN_TITLE_AUTHOR = __('Author');
export const TOKEN_TITLE_CONFIDENTIAL = __('Confidential');
export const TOKEN_TITLE_CONTACT = s__('Crm|Contact');
export const TOKEN_TITLE_LABEL = __('Label');
export const TOKEN_TITLE_MILESTONE = __('Milestone');
export const TOKEN_TITLE_MY_REACTION = __('My-Reaction');
export const TOKEN_TITLE_ORGANIZATION = s__('Crm|Organization');
export const TOKEN_TITLE_RELEASE = __('Release');
export const TOKEN_TITLE_SOURCE_BRANCH = __('Source Branch');
export const TOKEN_TITLE_STATUS = __('Status');
export const TOKEN_TITLE_TARGET_BRANCH = __('Target Branch');
export const TOKEN_TITLE_TYPE = __('Type');

// As health status gets reused between issue lists and boards
// this is in the shared constants. Until we have not decoupled the EE filtered search bar
// from the CE component, we need to keep this in the CE code.
// https://gitlab.com/gitlab-org/gitlab/-/issues/377838
export const TOKEN_TYPE_HEALTH = 'health_status';
