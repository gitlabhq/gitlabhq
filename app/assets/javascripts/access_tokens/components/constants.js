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
    tdClass: `gl-text-black-normal`,
    thClass: `gl-text-black-normal`,
  },
  {
    formatter(scopes) {
      return scopes?.length ? scopes.join(', ') : __('no scopes selected');
    },
    key: 'scopes',
    label: __('Scopes'),
    sortable: true,
    tdClass: `gl-text-black-normal`,
    thClass: `gl-text-black-normal`,
  },
  {
    key: 'createdAt',
    label: s__('AccessTokens|Created'),
    sortable: true,
    tdClass: `gl-text-black-normal`,
    thClass: `gl-text-black-normal`,
  },
  {
    key: 'lastUsedAt',
    label: __('Last Used'),
    sortable: true,
    tdClass: `gl-text-black-normal`,
    thClass: `gl-text-black-normal`,
  },
  {
    key: 'expiresAt',
    label: __('Expires'),
    sortable: true,
    tdClass: `gl-text-black-normal`,
    thClass: `gl-text-black-normal`,
  },
  {
    key: 'role',
    label: __('Role'),
    tdClass: `gl-text-black-normal`,
    thClass: `gl-text-black-normal`,
    sortable: true,
  },
  {
    key: 'action',
    label: __('Action'),
    thClass: `gl-text-black-normal`,
  },
];
