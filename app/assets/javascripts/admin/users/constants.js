import { s__, __ } from '~/locale';

export const USER_AVATAR_SIZE = 32;

export const LENGTH_OF_USER_NOTE_TOOLTIP = 100;

export const I18N_USER_ACTIONS = {
  edit: __('Edit'),
  settings: __('Settings'),
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
};

export const CONFIRM_DELETE_BUTTON_SELECTOR = '.js-delete-user-modal-button';

export const MODAL_TEXTS_CONTAINER_SELECTOR = '#js-modal-texts';

export const MODAL_MANAGER_SELECTOR = '#js-delete-user-modal';
