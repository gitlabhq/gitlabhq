import { __, s__ } from '~/locale';
import { STATUS_LABELS } from './constants';

export const getStatusLabel = (status) => STATUS_LABELS[status] ?? s__('IncidentManagement|None');

export const todoLabel = (hasTodo) => {
  return hasTodo ? __('Mark as done') : __('Add a to-do item');
};

/**
 * Optimistic update of to-do count, use this function if you have a delta
 * of todos after a user interaction, e.g. answering to a thread or closing an MR.
 *
 * This likely should be followed by re-fetching all user counts
 * @param {number} delta
 */
export const updateGlobalTodoCount = (delta) => {
  // Optimistic update of user counts
  document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { delta } }));
};
