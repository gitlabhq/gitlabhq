import { GlFilteredSearchToken } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import {
  OPERATORS_AFTER_BEFORE,
  OPERATORS_IS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import DateToken from '~/vue_shared/components/filtered_search_bar/tokens/date_token.vue';
import { fifteenDaysFromNow } from '~/vue_shared/access_tokens/utils';

export const PAGE_SIZE = 10;

export const DEFAULT_FILTER = [
  {
    type: 'state',
    value: {
      data: 'ACTIVE',
      operator: '=',
    },
  },
];

export const FILTER_OPTIONS = [
  {
    icon: 'status',
    title: s__('AccessTokens|State'),
    type: 'state',
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: 'ACTIVE', title: s__('AccessTokens|Active') },
      { value: 'INACTIVE', title: s__('AccessTokens|Inactive') },
    ],
  },
  {
    icon: 'remove',
    title: s__('AccessTokens|Revoked'),
    type: 'revoked',
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: true, title: __('Yes') },
      { value: false, title: __('No') },
    ],
  },
  {
    icon: 'history',
    title: __('Created date'),
    type: 'created',
    token: DateToken,
    operators: OPERATORS_AFTER_BEFORE,
    unique: true,
  },
  {
    icon: 'history',
    title: __('Expiration date'),
    type: 'expires',
    token: DateToken,
    operators: OPERATORS_AFTER_BEFORE,
    unique: true,
  },
  {
    icon: 'history',
    title: __('Last used date'),
    type: 'lastUsed',
    token: DateToken,
    operators: OPERATORS_AFTER_BEFORE,
    unique: true,
  },
];

export const DEFAULT_SORT = { value: 'expires', isAsc: true };

export const SORT_OPTIONS = [
  {
    text: __('Created date'),
    value: 'created',
    sort: {
      asc: 'created_asc',
      desc: 'created_desc',
    },
  },
  {
    text: __('Expiration date'),
    value: 'expires',
    sort: {
      asc: 'expires_asc',
      desc: 'expires_desc',
    },
  },
  {
    text: __('Last used date'),
    value: 'last_used',
    sort: {
      asc: 'last_used_asc',
      desc: 'last_used_desc',
    },
  },
  {
    text: __('Name'),
    value: 'name',
    sort: {
      asc: 'name_asc',
      desc: 'name_desc',
    },
  },
];

export const TABLE_FIELDS = [
  {
    key: 'name',
    label: __('Name'),
    tdClass: 'lg:gl-w-1/4',
  },
  {
    key: 'description',
    label: __('Description'),
    tdClass: 'lg:gl-w-1/3',
  },
  {
    key: 'status',
    label: __('Status'),
    tdClass: 'lg:gl-w-1/3',
  },
  {
    key: 'actions',
    label: __('Actions'),
    tdClass: 'gl-text-center',
  },
];

export const STATISTICS_FILTERS = {
  active: [
    {
      type: 'state',
      value: {
        data: 'ACTIVE',
        operator: '=',
      },
    },
  ],
  expiringSoon: [
    {
      type: 'state',
      value: {
        data: 'ACTIVE',
        operator: '=',
      },
    },
    {
      type: 'expires',
      value: {
        data: fifteenDaysFromNow(),
        operator: '<',
      },
    },
  ],
  revoked: [
    {
      type: 'revoked',
      value: {
        data: true,
        operator: '=',
      },
    },
  ],
  expired: [
    {
      type: 'revoked',
      value: {
        data: false,
        operator: '=',
      },
    },
    {
      type: 'state',
      value: {
        data: 'INACTIVE',
        operator: '=',
      },
    },
  ],
};

export const ACCESS_PERSONAL_PROJECTS_ENUM = 'PERSONAL_PROJECTS';
export const ACCESS_SELECTED_MEMBERSHIPS_ENUM = 'SELECTED_MEMBERSHIPS';
export const ACCESS_ALL_MEMBERSHIPS_ENUM = 'ALL_MEMBERSHIPS';
export const ACCESS_USER_ENUM = 'USER';
export const ACCESS_INSTANCE_ENUM = 'INSTANCE';

export const MAX_DESCRIPTION_LENGTH = 255;

export const SEARCH = 'search';

export const ACTIONS = {
  REVOKE: 'revoke',
  ROTATE: 'rotate',
};
