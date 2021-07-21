import { __ } from '~/locale';

export const DEBOUNCE_DELAY = 200;
export const MAX_RECENT_TOKENS_SIZE = 3;
export const WEIGHT_TOKEN_SUGGESTIONS_SIZE = 21;

export const FILTER_NONE = 'None';
export const FILTER_ANY = 'Any';
export const FILTER_CURRENT = 'Current';

export const OPERATOR_IS = '=';
export const OPERATOR_IS_TEXT = __('is');
export const OPERATOR_IS_NOT = '!=';
export const OPERATOR_IS_NOT_TEXT = __('is not');

export const OPERATOR_IS_ONLY = [{ value: OPERATOR_IS, description: OPERATOR_IS_TEXT }];
export const OPERATOR_IS_NOT_ONLY = [{ value: OPERATOR_IS_NOT, description: OPERATOR_IS_NOT_TEXT }];
export const OPERATOR_IS_AND_IS_NOT = [...OPERATOR_IS_ONLY, ...OPERATOR_IS_NOT_ONLY];

export const DEFAULT_LABEL_NONE = { value: FILTER_NONE, text: __(FILTER_NONE) };
export const DEFAULT_LABEL_ANY = { value: FILTER_ANY, text: __(FILTER_ANY) };
export const DEFAULT_NONE_ANY = [DEFAULT_LABEL_NONE, DEFAULT_LABEL_ANY];

export const DEFAULT_ITERATIONS = DEFAULT_NONE_ANY.concat([
  { value: FILTER_CURRENT, text: __(FILTER_CURRENT) },
]);

export const DEFAULT_LABELS = [DEFAULT_LABEL_NONE, DEFAULT_LABEL_ANY];

export const DEFAULT_MILESTONES = DEFAULT_NONE_ANY.concat([
  { value: 'Upcoming', text: __('Upcoming') }, // eslint-disable-line @gitlab/require-i18n-strings
  { value: 'Started', text: __('Started') }, // eslint-disable-line @gitlab/require-i18n-strings
]);

export const SortDirection = {
  descending: 'descending',
  ascending: 'ascending',
};

export const FILTERED_SEARCH_TERM = 'filtered-search-term';

export const TOKEN_TITLE_AUTHOR = __('Author');
export const TOKEN_TITLE_ASSIGNEE = __('Assignee');
export const TOKEN_TITLE_MILESTONE = __('Milestone');
export const TOKEN_TITLE_LABEL = __('Label');
export const TOKEN_TITLE_MY_REACTION = __('My-Reaction');
export const TOKEN_TITLE_CONFIDENTIAL = __('Confidential');
export const TOKEN_TITLE_ITERATION = __('Iteration');
export const TOKEN_TITLE_EPIC = __('Epic');
export const TOKEN_TITLE_WEIGHT = __('Weight');
