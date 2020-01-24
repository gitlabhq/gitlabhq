import dateformat from 'dateformat';
import { __ } from '~/locale';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';

/**
 * Valid strings for this regex are
 * 2019-10-01 and 2019-10-01 01:02:03
 */
const dateTimePickerRegex = /^(\d{4})-(0[1-9]|1[012])-(0[1-9]|[12][0-9]|3[01])(?: (0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]))?$/;

/**
 * A key-value pair of "time windows".
 *
 * A time window is a representation of period of time that starts
 * some time in past until now. Keys are only used for easy reference.
 *
 * It is represented as user friendly `label` and number of `seconds`
 * to be substracted from now.
 */
export const defaultTimeWindows = {
  thirtyMinutes: {
    label: __('30 minutes'),
    seconds: 60 * 30,
  },
  threeHours: {
    label: __('3 hours'),
    seconds: 60 * 60 * 3,
  },
  eightHours: {
    label: __('8 hours'),
    seconds: 60 * 60 * 8,
    default: true,
  },
  oneDay: {
    label: __('1 day'),
    seconds: 60 * 60 * 24 * 1,
  },
  threeDays: {
    label: __('3 days'),
    seconds: 60 * 60 * 24 * 3,
  },
};

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
 * For a given time window key (e.g. `threeHours`) and key-value pair
 * object of time windows.
 *
 * Returns a date time range with start and end.
 *
 * @param {String} timeWindowKey - A key in the object of time windows.
 * @param {Object} timeWindows - A key-value pair of time windows,
 * with a second duration and a label.
 * @returns An object with time range, start and end dates, in ISO format.
 */
export const getTimeRange = (timeWindowKey, timeWindows = defaultTimeWindows) => {
  let difference;
  if (timeWindows[timeWindowKey]) {
    difference = timeWindows[timeWindowKey].seconds;
  } else {
    const [defaultEntry] = Object.entries(timeWindows).filter(
      ([, timeWindow]) => timeWindow.default,
    );
    // find default time window
    difference = defaultEntry[1].seconds;
  }

  const end = Math.floor(Date.now() / 1000); // convert milliseconds to seconds
  const start = end - difference;

  return {
    start: new Date(secondsToMilliseconds(start)).toISOString(),
    end: new Date(secondsToMilliseconds(end)).toISOString(),
  };
};

export const getTimeWindowKey = ({ start, end }, timeWindows = defaultTimeWindows) =>
  Object.entries(timeWindows).reduce((acc, [timeWindowKey, timeWindow]) => {
    if (new Date(end) - new Date(start) === secondsToMilliseconds(timeWindow.seconds)) {
      return timeWindowKey;
    }
    return acc;
  }, null);

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
