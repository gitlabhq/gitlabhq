import dateformat from 'dateformat';
import { __ } from '~/locale';

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
  /**
   * Format used by users to input dates
   *
   * Note: Should be a format that can be parsed by Date.parse.
   */
  inputFormat: 'yyyy-mm-dd HH:MM:ss',
  /**
   * Format used to strip timezone from inputs
   */
  stripTimezoneFormat: "yyyy-mm-dd'T'HH:MM:ss'Z'",
};

/**
 * Returns true if the date can be parsed succesfully after
 * being typed by a user.
 *
 * It allows some ambiguity so validation is not strict.
 *
 * @param {string} value - Value as typed by the user
 * @returns true if the value can be parsed as a valid date, false otherwise
 */
export const isValidInputString = value => {
  try {
    // dateformat throws error that can be caught.
    // This is better than using `new Date()`
    if (value && value.trim()) {
      dateformat(value, 'isoDateTime');
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
};

/**
 * Convert the input in time picker component to an ISO date.
 *
 * @param {string} value
 * @param {Boolean} utc - If true, it forces the date to by
 * formatted using UTC format, ignoring the local time.
 * @returns {Date}
 */
export const inputStringToIsoDate = (value, utc = false) => {
  let date = new Date(value);
  if (utc) {
    // Forces date to be interpreted as UTC by stripping the timezone
    // by formatting to a string with 'Z' and skipping timezone
    date = dateformat(date, dateFormats.stripTimezoneFormat);
  }
  return dateformat(date, 'isoUtcDateTime');
};

/**
 * Converts a iso date string to a formatted string for the Time picker component.
 *
 * @param {String} ISO Formatted date
 * @returns {string}
 */
export const isoDateToInputString = (date, utc = false) =>
  dateformat(date, dateFormats.inputFormat, utc);

export default {};
