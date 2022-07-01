import { createAlert } from '~/flash';
import { s__ } from '~/locale';

export const displayAndLogError = (error) =>
  createAlert({
    message: s__('Incident|Something went wrong while fetching incident timeline events.'),
    captureError: true,
    error,
  });

const EVENT_ICONS = {
  comment: 'comment',
  issues: 'issues',
  status: 'status',
  default: 'comment',
};

export const getEventIcon = (actionName) => {
  return EVENT_ICONS[actionName] ?? EVENT_ICONS.default;
};
