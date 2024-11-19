import { __, s__ } from '~/locale';
import { STATUS_LABELS } from './constants';

export const getStatusLabel = (status) => STATUS_LABELS[status] ?? s__('IncidentManagement|None');

export const todoLabel = (hasTodo) => {
  return hasTodo ? __('Mark as done') : __('Add a to-do item');
};

export const updateGlobalTodoCount = (delta) => {
  // Optimistic update of user counts
  document.dispatchEvent(new CustomEvent('todo:toggle', { detail: { delta } }));
};
