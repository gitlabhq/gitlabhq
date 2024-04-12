import { GlFilteredSearchToken } from '@gitlab/ui';

import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { s__, __ } from '~/locale';

export const I18N_USER_ACTIONS = {
  edit: __('Edit'),
  userAdministration: s__('AdminUsers|User administration'),
  unlock: __('Unlock'),
  block: s__('AdminUsers|Block'),
  unblock: s__('AdminUsers|Unblock'),
  approve: s__('AdminUsers|Approve'),
  reject: s__('AdminUsers|Reject'),
  deactivate: s__('AdminUsers|Deactivate'),
  activate: s__('AdminUsers|Activate'),
  ldapBlocked: s__('AdminUsers|Cannot unblock LDAP blocked users'),
  delete: s__('AdminUsers|Delete user'),
  deleteWithContributions: s__('AdminUsers|Delete user and contributions'),
  ban: s__('AdminUsers|Ban user'),
  unban: s__('AdminUsers|Unban user'),
  trust: s__('AdminUsers|Trust user'),
  untrust: s__('AdminUsers|Untrust user'),
};

const OPTION_ADMINS = 'admins';
const OPTION_2FA_ENABLED = 'two_factor_enabled';
const OPTION_2FA_DISABLED = 'two_factor_disabled';
const OPTION_EXTERNAL = 'external';
const OPTION_BLOCKED = 'blocked';
const OPTION_BANNED = 'banned';
const OPTION_BLOCKED_PENDING_APPROVAL = 'blocked_pending_approval';
const OPTION_DEACTIVATED = 'deactivated';
const OPTION_WOP = 'wop';
const OPTION_TRUSTED = 'trusted';

export const TOKEN_ACCESS_LEVEL = 'access_level';
export const TOKEN_STATE = 'state';
export const TOKEN_2FA = '2fa';

export const TOKEN_TYPES = [TOKEN_ACCESS_LEVEL, TOKEN_STATE, TOKEN_2FA];

export const TOKENS = [
  {
    title: s__('AdminUsers|Access level'),
    type: TOKEN_ACCESS_LEVEL,
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: OPTION_ADMINS, title: s__('AdminUsers|Administrator') },
      { value: OPTION_EXTERNAL, title: s__('AdminUsers|External') },
    ],
  },
  {
    title: __('State'),
    type: TOKEN_STATE,
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: OPTION_BANNED, title: s__('AdminUsers|Banned') },
      { value: OPTION_BLOCKED, title: s__('AdminUsers|Blocked') },
      { value: OPTION_DEACTIVATED, title: s__('AdminUsers|Deactivated') },
      {
        value: OPTION_BLOCKED_PENDING_APPROVAL,
        title: s__('AdminUsers|Pending approval'),
      },
      { value: OPTION_TRUSTED, title: s__('AdminUsers|Trusted') },
      { value: OPTION_WOP, title: s__('AdminUsers|Without projects') },
    ],
  },
  {
    title: s__('AdminUsers|Two-factor authentication'),
    type: TOKEN_2FA,
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: OPTION_2FA_ENABLED, title: __('On') },
      { value: OPTION_2FA_DISABLED, title: __('Off') },
    ],
  },
];
