import { createAlert } from '~/alert';
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
  label: 'label',
  status: 'status',
  default: 'comment',
};

export const getEventIcon = (actionName) => {
  return EVENT_ICONS[actionName] ?? EVENT_ICONS.default;
};

/**
 * Returns a date shifted by the current timezone offset set to now
 * by default but can accept an existing date as an ISO date string
 * @param {string} ISOString
 * @returns {Date}
 */
export const getUtcShiftedDate = (ISOString = null) => {
  const date = ISOString ? new Date(ISOString) : new Date();
  date.setMinutes(date.getMinutes() + date.getTimezoneOffset());

  return date;
};

/**
 * Returns an array of previously set event tags
 * @param {array} timelineEventTagsNodes
 * @returns {array}
 */
export const getPreviousEventTags = (timelineEventTagsNodes = []) =>
  timelineEventTagsNodes.map(({ name }) => name);
