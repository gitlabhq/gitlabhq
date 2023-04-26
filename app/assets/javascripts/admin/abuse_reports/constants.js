import { getUsers } from '~/rest_api';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import {
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { __ } from '~/locale';

const STATUS_OPTIONS = [
  { value: 'closed', title: __('Closed') },
  { value: 'open', title: __('Open') },
];

export const FILTERED_SEARCH_TOKEN_USER = {
  type: 'user',
  icon: 'user',
  title: __('User'),
  token: UserToken,
  unique: true,
  operators: OPERATORS_IS,
  fetchUsers: getUsers,
  defaultUsers: [],
};

export const FILTERED_SEARCH_TOKEN_REPORTER = {
  ...FILTERED_SEARCH_TOKEN_USER,
  type: 'reporter',
  title: __('Reporter'),
};

export const FILTERED_SEARCH_TOKEN_STATUS = {
  type: 'status',
  icon: 'status',
  title: TOKEN_TITLE_STATUS,
  token: BaseToken,
  unique: true,
  options: STATUS_OPTIONS,
  operators: OPERATORS_IS,
};

export const DEFAULT_SORT = 'created_at_desc';
export const SORT_UPDATED_AT = Object.freeze({
  id: 20,
  title: __('Updated date'),
  sortDirection: {
    descending: 'updated_at_desc',
    ascending: 'updated_at_asc',
  },
});
const SORT_CREATED_AT = Object.freeze({
  id: 10,
  title: __('Created date'),
  sortDirection: {
    descending: DEFAULT_SORT,
    ascending: 'created_at_asc',
  },
});

export const SORT_OPTIONS = [SORT_CREATED_AT, SORT_UPDATED_AT];

export const isValidSortKey = (key) =>
  SORT_OPTIONS.some(
    (sort) => sort.sortDirection.ascending === key || sort.sortDirection.descending === key,
  );

export const FILTERED_SEARCH_TOKEN_CATEGORY = {
  type: 'category',
  icon: 'label',
  title: __('Category'),
  token: BaseToken,
  unique: true,
  operators: OPERATORS_IS,
};

export const FILTERED_SEARCH_TOKENS = [
  FILTERED_SEARCH_TOKEN_USER,
  FILTERED_SEARCH_TOKEN_REPORTER,
  FILTERED_SEARCH_TOKEN_STATUS,
];

export const ACTIONS_I18N = {
  blockUserConfirm: __('USER WILL BE BLOCKED! Are you sure?'),
  blockUser: __('Block user'),
  alreadyBlocked: __('Already blocked'),
  removeUserAndReportConfirm: __('USER %{user} WILL BE REMOVED! Are you sure?'),
  removeUserAndReport: __('Remove user & report'),
  removeReport: __('Remove report'),
  actionsToggleText: __('Actions'),
};
