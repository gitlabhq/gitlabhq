import { __, s__ } from '~/locale';

export const EVENT_ERROR = 'ajax:error';
export const EVENT_SUCCESS = 'ajax:success';
export const FORM_SELECTOR = '#js-new-access-token-form';

export const INITIAL_PAGE = 1;
export const PAGE_SIZE = 100;

const BASE_FIELDS = [
  {
    key: 'name',
    label: __('Token name'),
    isRowHeader: true,
    sortable: true,
  },
  {
    formatter(description) {
      return description ?? '-';
    },
    key: 'description',
    label: __('Description'),
    sortable: true,
  },
  {
    formatter(scopes) {
      return scopes?.length ? scopes.join(', ') : __('no scopes selected');
    },
    key: 'scopes',
    label: __('Scopes'),
    sortable: true,
  },
  {
    key: 'createdAt',
    label: s__('AccessTokens|Created'),
    sortable: true,
  },
  {
    key: 'lastUsedAt',
    label: __('Last Used'),
    sortable: true,
  },
];

const ROLE_FIELD = {
  key: 'role',
  label: __('Role'),
  sortable: true,
};

export const FIELDS = [
  ...BASE_FIELDS,
  {
    formatter(ips) {
      return ips?.length ? ips?.join(', ') : '-';
    },
    key: 'lastUsedIps',
    label: __('Last Used IPs'),
    sortable: false,
  },
  {
    key: 'expiresAt',
    label: __('Expires'),
    sortable: true,
  },
  ROLE_FIELD,
  {
    key: 'action',
    label: __('Action'),
    tdClass: '!gl-py-3',
  },
];

export const INACTIVE_TOKENS_TABLE_FIELDS = [
  ...BASE_FIELDS,
  {
    key: 'expiresAt',
    label: __('Expired'),
    sortable: true,
  },
  ROLE_FIELD,
];
