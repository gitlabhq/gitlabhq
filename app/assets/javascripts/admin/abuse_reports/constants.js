import { getUsers } from '~/rest_api';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import {
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { s__, __ } from '~/locale';

export const STATUS_OPEN = { value: 'open', title: __('Open') };

const STATUS_OPTIONS = [{ value: 'closed', title: __('Closed') }, STATUS_OPEN];

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
  title: s__('AbuseReport|Reporter'),
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

export const DEFAULT_SORT_STATUS_OPEN = 'number_of_reports_desc';
export const DEFAULT_SORT_STATUS_CLOSED = 'created_at_desc';

export const SORT_UPDATED_AT = {
  id: 20,
  title: __('Updated date'),
  sortDirection: {
    descending: 'updated_at_desc',
    ascending: 'updated_at_asc',
  },
};

const SORT_CREATED_AT = {
  id: 10,
  title: __('Created date'),
  sortDirection: {
    descending: DEFAULT_SORT_STATUS_CLOSED,
    ascending: 'created_at_asc',
  },
};

const SORT_NUMBER_OF_REPORTS = {
  id: 30,
  title: __('Number of Reports'),
  sortDirection: {
    descending: DEFAULT_SORT_STATUS_OPEN,
  },
};

export const SORT_OPTIONS_STATUS_CLOSED = [SORT_CREATED_AT, SORT_UPDATED_AT];

// when filtered for status=open reports, add an additional sorting option -> number of reports
export const SORT_OPTIONS_STATUS_OPEN = [SORT_NUMBER_OF_REPORTS, ...SORT_OPTIONS_STATUS_CLOSED];

export const FILTERED_SEARCH_TOKEN_CATEGORY = {
  type: 'category',
  icon: 'label',
  title: __('Category'),
  token: BaseToken,
  unique: true,
  operators: OPERATORS_IS,
};

export const FILTERED_SEARCH_TOKENS = [
  FILTERED_SEARCH_TOKEN_STATUS,
  FILTERED_SEARCH_TOKEN_USER,
  FILTERED_SEARCH_TOKEN_REPORTER,
];

export const ABUSE_CATEGORIES = {
  spam: {
    backgroundColor: '#f5d9a8',
    textColor: 'gl-text-orange-700',
    title: s__('AbuseReport|Spam'),
  },
  offensive: {
    backgroundColor: '#e1d8f9',
    textColor: 'gl-text-purple-700',
    title: s__('AbuseReport|Offensive or Abusive'),
  },
  phishing: {
    backgroundColor: '#7c7ccc',
    textColor: 'gl-text-indigo-800',
    title: s__('AbuseReport|Phishing'),
  },
  crypto: {
    backgroundColor: '#fdd4cd',
    textColor: 'gl-text-red-700',
    title: s__('AbuseReport|Crypto Mining'),
  },
  credentials: {
    backgroundColor: '#cbe2f9',
    textColor: 'gl-text-blue-700',
    title: s__('AbuseReport|Personal information or credentials'),
  },
  copyright: {
    backgroundColor: '#c3e6cd',
    textColor: 'gl-text-success',
    title: s__('AbuseReport|Copyright or trademark violation'),
  },
  malware: {
    backgroundColor: '#fdd4cd',
    textColor: 'gl-text-red-700',
    title: s__('AbuseReport|Malware'),
  },
  other: {
    backgroundColor: '#dcdcde',
    textColor: 'gl-text-gray-700',
    title: s__('AbuseReport|Other'),
  },
};
