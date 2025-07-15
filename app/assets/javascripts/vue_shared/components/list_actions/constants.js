import { __ } from '~/locale';

export const ACTION_EDIT = 'edit';
export const ACTION_LEAVE = 'leave';
export const ACTION_RESTORE = 'restore';
export const ACTION_DELETE = 'delete';
export const ACTION_DELETE_IMMEDIATELY = 'delete-immediately';

export const BASE_ACTIONS = {
  [ACTION_EDIT]: {
    text: __('Edit'),
  },
  [ACTION_RESTORE]: {
    text: __('Restore'),
  },
  [ACTION_LEAVE]: {
    text: __('Leave group'),
    variant: 'danger',
  },
  [ACTION_DELETE]: {
    text: __('Delete'),
    variant: 'danger',
  },
  [ACTION_DELETE_IMMEDIATELY]: {
    text: __('Delete immediately'),
    variant: 'danger',
  },
};
