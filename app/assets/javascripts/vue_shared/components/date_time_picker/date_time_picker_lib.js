import dateformat from 'dateformat';
import { __ } from '~/locale';

/**
 * Valid strings for this regex are
 * 2019-10-01 and 2019-10-01 01:02:03
 */
const dateTimePickerRegex = /^(\d{4})-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])(?: (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]))?$/;

/**
 * Default time ranges for the date picker.
 * @see app/assets/javascripts/lib/utils/datetime_range.js
 */
export const defaultTimeRanges = [
  {
    duration: { seconds: 60 * 30 },
    label: __('30 minutes'),
  },
  {
    duration: { seconds: 60 * 60 * 3 },
    label: __('3 hours'),
  },
  {
    duration: { seconds: 60 * 60 * 8 },
    label: __('8 hours'),
    default: true,
  },
  {
    duration: { seconds: 60 * 60 * 24 * 1 },
    label: __('1 day'),
  },
];

export const defaultTimeRange = defaultTimeRanges.find(tr => tr.default);

export const dateFormats = {
  ISODate: "yyyy-mm-dd'T'HH:MM:ss'Z'",
  stringDate: 'yyyy-mm-dd HH:MM:ss',
};

/**
 * The URL params start and end need to be validated
 * before passing them down to other components.
 *
 * @param {string} dateString
 * @returns true if the string is a valid date, false otherwise
 */
export const isValidDate = dateString => {
  try {
    // dateformat throws error that can be caught.
    // This is better than using `new Date()`
    if (dateString && dateString.trim()) {
      dateformat(dateString, 'isoDateTime');
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
};

/**
 * Convert the input in Time picker component to ISO date.
 *
 * @param {string} val
 * @returns {string}
 */
export const stringToISODate = val =>
  dateformat(new Date(val.replace(/-/g, '/')), dateFormats.ISODate, true);

/**
 * Convert the ISO date received from the URL to string
 * for the Time picker component.
 *
 * @param {Date} date
 * @returns {string}
 */
export const ISODateToString = date => dateformat(date, dateFormats.stringDate);

export const truncateZerosInDateTime = datetime => datetime.replace(' 00:00:00', '');

export const isDateTimePickerInputValid = val => dateTimePickerRegex.test(val);

export default {};
