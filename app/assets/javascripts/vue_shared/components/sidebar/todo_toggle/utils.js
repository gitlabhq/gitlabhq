import { __ } from '~/locale';

export const todoLabel = (hasTodo) => {
  return hasTodo ? __('Mark as done') : __('Add a to do');
};
