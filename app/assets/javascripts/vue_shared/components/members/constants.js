import { __ } from '~/locale';

export const FIELDS = [
  {
    key: 'account',
    label: __('Account'),
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
  },
  {
    key: 'expiration',
    label: __('Expiration'),
    thClass: 'col-expiration',
    tdClass: 'col-expiration',
  },
  {
    key: 'actions',
    thClass: 'col-actions',
    tdClass: 'col-actions',
    showFunction: 'showActionsField',
  },
];

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
