import { __ } from '~/locale';

export const ACTION_EDIT = 'edit';
export const ACTION_ARCHIVE = 'archive';
export const ACTION_UNARCHIVE = 'unarchive';
export const ACTION_RESTORE = 'restore';
export const ACTION_LEAVE = 'leave';
export const ACTION_DELETE = 'delete';
export const ACTION_DELETE_IMMEDIATELY = 'delete-immediately';

export const DANGER_ACTIONS = [ACTION_LEAVE, ACTION_DELETE, ACTION_DELETE_IMMEDIATELY];

/**
 * These are the default action item definitions that are passed to
 * `GlDisclosureDropdownItem` as the `item` prop.
 * Properties can be overridden or extended by the `actions` prop in `list_actions.vue`
 */
export const DEFAULT_ACTION_ITEM_DEFINITIONS = {
  [ACTION_EDIT]: {
    text: __('Edit'),
  },
  [ACTION_ARCHIVE]: {
    text: __('Archive'),
  },
  [ACTION_UNARCHIVE]: {
    text: __('Unarchive'),
  },
  [ACTION_RESTORE]: {
    text: __('Restore'),
  },
  [ACTION_LEAVE]: {
    text: __('Leave'),
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
