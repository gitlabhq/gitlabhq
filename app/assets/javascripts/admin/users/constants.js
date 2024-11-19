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

export const TOKENS = [
  {
    title: s__('AdminUsers|Access level'),
    type: 'access_level',
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: 'admins', title: s__('AdminUsers|Administrator') },
      { value: 'external', title: s__('AdminUsers|External') },
    ],
  },
  {
    title: __('State'),
    type: 'state',
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: 'active', title: s__('AdminUsers|Active') },
      { value: 'banned', title: s__('AdminUsers|Banned') },
      { value: 'blocked', title: s__('AdminUsers|Blocked') },
      { value: 'deactivated', title: s__('AdminUsers|Deactivated') },
      {
        value: 'blocked_pending_approval',
        title: s__('AdminUsers|Pending approval'),
      },
      { value: 'trusted', title: s__('AdminUsers|Trusted') },
      { value: 'wop', title: s__('AdminUsers|Without projects') },
    ],
  },
  {
    title: s__('AdminUsers|Two-factor authentication'),
    type: '2fa',
    token: GlFilteredSearchToken,
    operators: OPERATORS_IS,
    unique: true,
    options: [
      { value: 'two_factor_enabled', title: __('On') },
      { value: 'two_factor_disabled', title: __('Off') },
    ],
  },
];

export const SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT = 10;

export const SOLO_OWNED_ORGANIZATIONS_EMPTY = {
  count: 0,
  nodes: [],
};
