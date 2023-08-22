import { __ } from '~/locale';

export const ACTION_EDIT = 'edit';
export const ACTION_DELETE = 'delete';

export const BASE_ACTIONS = {
  [ACTION_EDIT]: {
    text: __('Edit'),
  },
  [ACTION_DELETE]: {
    text: __('Delete'),
    extraAttrs: {
      class: 'gl-text-red-500!',
    },
  },
};
