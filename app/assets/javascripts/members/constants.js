import { __ } from '~/locale';

export const FIELDS = [
  {
    key: 'account',
    label: __('Account'),
    sort: {
      asc: 'name_asc',
      desc: 'name_desc',
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
      asc: 'last_joined',
      desc: 'oldest_joined',
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
    key: 'maxRole',
    label: __('Max role'),
    thClass: 'col-max-role',
    tdClass: 'col-max-role',
    sort: {
      asc: 'access_level_asc',
      desc: 'access_level_desc',
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
    label: __('Last sign-in'),
    sort: {
      asc: 'recent_sign_in',
      desc: 'oldest_sign_in',
    },
  },
  {
    key: 'actions',
    thClass: 'col-actions',
    showFunction: 'showActionsField',
    tdClassFunction: 'tdClassActions',
  },
];

export const DEFAULT_SORT = {
  sortByKey: 'account',
  sortDesc: false,
};

export const AVATAR_SIZE = 48;

export const MEMBER_TYPES = {
  user: 'user',
  group: 'group',
  invite: 'invite',
  accessRequest: 'accessRequest',
};

export const TAB_QUERY_PARAM_VALUES = {
  group: 'groups',
  invite: 'invited',
  accessRequest: 'access_requests',
};

/**
 * This user state value comes from the User model
 * see the state machine in app/models/user.rb
 */
export const USER_STATE_BLOCKED_PENDING_APPROVAL = 'blocked_pending_approval';

/**
 * This and following member state constants' values
 * come from ee/app/models/ee/member.rb
 */
export const MEMBER_STATE_CREATED = 0;
export const MEMBER_STATE_AWAITING = 1;
export const MEMBER_STATE_ACTIVE = 2;

export const BADGE_LABELS_PENDING_OWNER_APPROVAL = __('Pending owner approval');

export const DAYS_TO_EXPIRE_SOON = 7;

export const LEAVE_MODAL_ID = 'member-leave-modal';

export const REMOVE_GROUP_LINK_MODAL_ID = 'remove-group-link-modal-id';

export const SEARCH_TOKEN_TYPE = 'filtered-search-term';

export const SORT_QUERY_PARAM_NAME = 'sort';
export const ACTIVE_TAB_QUERY_PARAM_NAME = 'tab';

export const MEMBER_ACCESS_LEVEL_PROPERTY_NAME = 'access_level';

export const GROUP_LINK_BASE_PROPERTY_NAME = 'group_link';
export const GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME = 'group_access';
