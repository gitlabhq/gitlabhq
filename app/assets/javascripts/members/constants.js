import { __, s__ } from '~/locale';

const ACCOUNT_SORT_ASC_LABEL = s__('Members|Account, ascending');

export const FIELDS = [
  {
    key: 'account',
    label: __('Account'),
    sort: {
      asc: {
        param: 'name_asc',
        label: ACCOUNT_SORT_ASC_LABEL,
      },
      desc: {
        param: 'name_desc',
        label: s__('Members|Account, descending'),
      },
    },
  },
  {
    key: 'source',
    label: __('Source'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'granted',
    label: __('Access granted'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
    sort: {
      asc: {
        param: 'last_joined',
        label: s__('Members|Access granted, ascending'),
      },
      desc: {
        param: 'oldest_joined',
        label: s__('Members|Access granted, descending'),
      },
    },
  },
  {
    key: 'invited',
    label: __('Invited'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'requested',
    label: __('Requested'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'expires',
    label: __('Access expires'),
    thClass: 'col-meta',
    tdClass: 'col-meta',
  },
  {
    key: 'maxRole',
    label: __('Max role'),
    thClass: 'col-max-role',
    tdClass: 'col-max-role',
    sort: {
      asc: {
        param: 'access_level_asc',
        label: s__('Members|Max role, ascending'),
      },
      desc: {
        param: 'access_level_desc',
        label: s__('Members|Max role, descending'),
      },
    },
  },
  {
    key: 'expiration',
    label: __('Expiration'),
    thClass: 'col-expiration',
    tdClass: 'col-expiration',
  },
  {
    key: 'lastSignIn',
    sort: {
      asc: {
        param: 'recent_sign_in',
        label: s__('Members|Last sign-in, ascending'),
      },
      desc: {
        param: 'oldest_sign_in',
        label: s__('Members|Last sign-in, descending'),
      },
    },
  },
  {
    key: 'actions',
    thClass: 'col-actions',
    tdClass: 'col-actions',
    showFunction: 'showActionsField',
  },
];

export const DEFAULT_SORT = {
  sortBy: 'account',
  sortDesc: false,
  sortByLabel: ACCOUNT_SORT_ASC_LABEL,
};

export const AVATAR_SIZE = 48;

export const MEMBER_TYPES = {
  user: 'user',
  group: 'group',
  invite: 'invite',
  accessRequest: 'accessRequest',
};

export const DAYS_TO_EXPIRE_SOON = 7;

export const LEAVE_MODAL_ID = 'member-leave-modal';

export const REMOVE_GROUP_LINK_MODAL_ID = 'remove-group-link-modal-id';

export const SEARCH_TOKEN_TYPE = 'filtered-search-term';

export const SORT_PARAM = 'sort';
