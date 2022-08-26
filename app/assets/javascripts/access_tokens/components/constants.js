import { __, s__ } from '~/locale';

export const EVENT_ERROR = 'ajax:error';
export const EVENT_SUCCESS = 'ajax:success';
export const FORM_SELECTOR = '#js-new-access-token-form';

export const INITIAL_PAGE = 1;
export const PAGE_SIZE = 100;

export const FIELDS = [
  {
    key: 'name',
    label: __('Token name'),
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
  {
    key: 'expiresAt',
    label: __('Expires'),
    sortable: true,
  },
  {
    key: 'role',
    label: __('Role'),
    sortable: true,
  },
  {
    key: 'action',
    label: __('Action'),
    tdClass: 'gl-py-3!',
  },
];
