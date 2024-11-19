import { GlFilteredSearchToken } from '@gitlab/ui';

import { __, s__ } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';

// Overridden in EE
export const GROUPS_APP_OPTIONS = {};
export const PROJECTS_APP_OPTIONS = {};

export const ACTION_BUTTONS = {};

export const FIELD_KEY_ACCOUNT = 'account';
export const FIELD_KEY_SOURCE = 'source';
export const FIELD_KEY_GRANTED = 'granted';
export const FIELD_KEY_INVITED = 'invited';
export const FIELD_KEY_REQUESTED = 'requested';
export const FIELD_KEY_MAX_ROLE = 'maxRole';
export const FIELD_KEY_USER_CREATED_AT = 'userCreatedAt';
export const FIELD_KEY_LAST_ACTIVITY_ON = 'lastActivityOn';
export const FIELD_KEY_EXPIRATION = 'expiration';
export const FIELD_KEY_ACTIVITY = 'activity';
export const FIELD_KEY_LAST_SIGN_IN = 'lastSignIn';
export const FIELD_KEY_ACTIONS = 'actions';

export const FIELDS = [
  {
    key: FIELD_KEY_ACCOUNT,
    label: __('Account'),
    sort: {
      asc: 'name_asc',
      desc: 'name_desc',
    },
    tdClass: '!gl-align-middle',
  },
  {
    key: FIELD_KEY_SOURCE,
    label: __('Source'),
    thClass: 'col-meta',
    tdClass: 'col-meta !gl-align-middle',
  },
  {
    key: FIELD_KEY_GRANTED,
    label: __('Access granted'),
    sort: {
      asc: 'last_joined',
      desc: 'oldest_joined',
    },
    tdClass: '!gl-align-middle',
  },
  {
    key: FIELD_KEY_INVITED,
    label: __('Invited'),
    thClass: 'col-meta',
    tdClass: 'col-meta !gl-align-middle',
  },
  {
    key: FIELD_KEY_REQUESTED,
    label: __('Requested'),
    thClass: 'col-meta',
    tdClass: 'col-meta !gl-align-middle',
  },
  {
    key: FIELD_KEY_MAX_ROLE,
    label: __('Role'),
    thClass: 'col-max-role',
    tdClass: 'col-max-role !gl-align-middle',
    sort: {
      asc: 'access_level_asc',
      desc: 'access_level_desc',
    },
  },
  {
    key: FIELD_KEY_EXPIRATION,
    label: __('Expiration'),
    thClass: 'col-expiration',
    tdClass: 'col-expiration !gl-align-middle',
  },
  {
    key: FIELD_KEY_ACTIVITY,
    label: s__('Members|Activity'),
    thClass: 'col-activity',
    tdClass: 'col-activity !gl-align-middle',
  },
  {
    key: FIELD_KEY_USER_CREATED_AT,
    label: s__('Members|User created'),
    sort: {
      asc: 'oldest_created_user',
      desc: 'recent_created_user',
    },
  },
  {
    key: FIELD_KEY_LAST_ACTIVITY_ON,
    label: __('Last activity'),
    sort: {
      asc: 'oldest_last_activity',
      desc: 'recent_last_activity',
    },
  },
  {
    key: FIELD_KEY_LAST_SIGN_IN,
    label: __('Last sign-in'),
    sort: {
      asc: 'recent_sign_in',
      desc: 'oldest_sign_in',
    },
  },
  {
    key: FIELD_KEY_ACTIONS,
    thClass: 'col-actions',
  },
];

export const DEFAULT_SORT = {
  sortByKey: 'account',
  sortDesc: false,
};

export const FILTERED_SEARCH_TOKEN_TWO_FACTOR = {
  type: 'two_factor',
  icon: 'lock',
  title: s__('Members|2FA'),
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  options: [
    { value: 'enabled', title: s__('Members|Enabled') },
    { value: 'disabled', title: s__('Members|Disabled') },
  ],
  requiredPermissions: 'canManageMembers',
};

export const FILTERED_SEARCH_TOKEN_WITH_INHERITED_PERMISSIONS = {
  type: 'with_inherited_permissions',
  icon: 'group',
  title: s__('Members|Membership'),
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
  options: [
    { value: 'exclude', title: s__('Members|Direct') },
    { value: 'only', title: s__('Members|Indirect') },
  ],
};

export const FILTERED_SEARCH_TOKEN_GROUPS_WITH_INHERITED_PERMISSIONS = {
  ...FILTERED_SEARCH_TOKEN_WITH_INHERITED_PERMISSIONS,
  type: 'groups_with_inherited_permissions',
};

export const FILTERED_SEARCH_MAX_ROLE = {
  type: 'max_role',
  icon: 'shield',
  title: __('Role'),
  token: GlFilteredSearchToken,
  unique: true,
  operators: OPERATORS_IS,
};

export const AVAILABLE_FILTERED_SEARCH_TOKENS = [
  FILTERED_SEARCH_TOKEN_TWO_FACTOR,
  FILTERED_SEARCH_TOKEN_WITH_INHERITED_PERMISSIONS,
  FILTERED_SEARCH_TOKEN_GROUPS_WITH_INHERITED_PERMISSIONS,
  FILTERED_SEARCH_MAX_ROLE,
];

export const AVATAR_SIZE = 48;

export const DEFAULT_PAGE_SIZE = 20;

export const MEMBERS_TAB_TYPES = Object.freeze({
  user: 'user',
  group: 'group',
  invite: 'invite',
  accessRequest: 'accessRequest',
  placeholder: 'placeholder',
});

// `app/models/members/group_member.rb`
export const MEMBER_MODEL_TYPE_GROUP_MEMBER = 'GroupMember';

// `app/models/members/project_member.rb`
export const MEMBER_MODEL_TYPE_PROJECT_MEMBER = 'ProjectMember';

export const TAB_QUERY_PARAM_VALUES = Object.freeze({
  group: 'groups',
  invite: 'invited',
  accessRequest: 'access_requests',
  placeholder: 'placeholders',
});

/**
 * This user state value comes from the User model
 * see the state machine in app/models/user.rb
 */
export const USER_STATE_BLOCKED = 'blocked_pending_approval';

/**
 * This and following member state constants' values
 * come from ee/app/models/ee/member.rb
 */
export const MEMBER_STATE_CREATED = 0;
export const MEMBER_STATE_AWAITING = 1;
export const MEMBER_STATE_ACTIVE = 2;

export const BADGE_LABELS_AWAITING_SIGNUP = __('Awaiting user signup');
export const BADGE_LABELS_PENDING = __('Pending owner action');

export const LEAVE_MODAL_ID = 'member-leave-modal';

export const REMOVE_GROUP_LINK_MODAL_ID = 'remove-group-link-modal-id';

export const SORT_QUERY_PARAM_NAME = 'sort';
export const ACTIVE_TAB_QUERY_PARAM_NAME = 'tab';
export const ACTIVE_SUBTAB_QUERY_PARAM = 'subtab';

export const MEMBER_ACCESS_LEVEL_PROPERTY_NAME = 'access_level';

export const GROUP_LINK_BASE_PROPERTY_NAME = 'group_link';
export const GROUP_LINK_ACCESS_LEVEL_PROPERTY_NAME = 'group_access';

export const I18N_USER_YOU = __("It's you");
export const I18N_USER_BLOCKED = __('Blocked');
export const I18N_USER_BOT = __('Bot');
export const I188N_USER_2FA = __('2FA');
export const I18N_ROLE_SAVE_SUCCESS = s__('Members|Role was successfully updated.');
export const I18N_ROLE_SAVE_ERROR = s__('MemberRole|Could not update role.');

export const CONTEXT_TYPE = Object.freeze({
  PROJECT: 'PROJECT',
  GROUP: 'GROUP',
});
