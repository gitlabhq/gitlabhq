import { isString, mapValues, reduce, isDate, unescape } from 'lodash';
import dateFormat from '~/lib/dateformat';
import { roundToNearestHalf } from '~/lib/utils/common_utils';
import { sanitize } from '~/lib/dompurify';
import { s__, n__, __, sprintf } from '~/locale';
import { parsePikadayDate } from './pikaday_utility';

/**
 * Returns i18n month names array.
 * If `abbreviated` is provided, returns abbreviated
 * name.
 *
 * @param {Boolean} abbreviated
 */
export const getMonthNames = (abbreviated) => {
  if (abbreviated) {
    return [
      __('Jan'),
      __('Feb'),
      __('Mar'),
      __('Apr'),
      __('May'),
      __('Jun'),
      __('Jul'),
      __('Aug'),
      __('Sep'),
      __('Oct'),
      __('Nov'),
      __('Dec'),
    ];
  }
  return [
    __('January'),
    __('February'),
    __('March'),
    __('April'),
    __('May'),
    __('June'),
    __('July'),
    __('August'),
    __('September'),
    __('October'),
    __('November'),
    __('December'),
  ];
};

/**
 * Returns month name based on provided date.
 *
 * @param {Date} date
 * @param {Boolean} abbreviated
 */
export const monthInWords = (date, abbreviated = false) => {
  if (!date) {
    return '';
  }

  return getMonthNames(abbreviated)[date.getMonth()];
};

export const dateInWords = (date, abbreviated = false, hideYear = false) => {
  if (!date) return date;

  const month = date.getMonth();
  const year = date.getFullYear();

  const monthName = getMonthNames(abbreviated)[month];

  if (hideYear) {
    return `${monthName} ${date.getDate()}`;
  }

  return `${monthName} ${date.getDate()}, ${year}`;
};

/**
 * Similar to `timeIntervalInWords`, but rounds the return value
 * to 1/10th of the largest time unit. For example:
 *
 * 30 => 30 seconds
 * 90 => 1.5 minutes
 * 7200 => 2 hours
 * 86400 => 1 day
 * ... etc.
 *
 * The largest supported unit is "days".
 *
 * @param {Number} intervalInSeconds The time interval in seconds
 * @returns {String} A humanized description of the time interval
 */
export const humanizeTimeInterval = (intervalInSeconds) => {
  if (intervalInSeconds < 60 /* = 1 minute */) {
    const seconds = Math.round(intervalInSeconds * 10) / 10;
    return n__('%d second', '%d seconds', seconds);
  }
  if (intervalInSeconds < 3600 /* = 1 hour */) {
    const minutes = Math.round(intervalInSeconds / 6) / 10;
    return n__('%d minute', '%d minutes', minutes);
  }
  if (intervalInSeconds < 86400 /* = 1 day */) {
    const hours = Math.round(intervalInSeconds / 360) / 10;
    return n__('%d hour', '%d hours', hours);
  }

  const days = Math.round(intervalInSeconds / 8640) / 10;
  return n__('%d day', '%d days', days);
};

/**
 * Returns i18n weekday names array.
 */
export const getWeekdayNames = () => [
  __('Sunday'),
  __('Monday'),
  __('Tuesday'),
  __('Wednesday'),
  __('Thursday'),
  __('Friday'),
  __('Saturday'),
];

/**
 * Given a date object returns the day of the week in English
 * @param {date} date
 * @returns {String}
 */
export const getDayName = (date) => getWeekdayNames()[date.getDay()];

/**
 * Returns the i18n month name from a given date
 * @example
 * formatDateAsMonth(new Date('2020-06-28')) -> 'Jun'
 * @param  {String} datetime where month is extracted from
 * @param  {Object} options
 * @param  {Boolean} options.abbreviated whether to use the abbreviated month string, or not
 * @return {String} the i18n month name
 */
export function formatDateAsMonth(datetime, options = {}) {
  const { abbreviated = true } = options;
  const month = new Date(datetime).getMonth();
  return getMonthNames(abbreviated)[month];
}

/**
 * @example
 * dateFormat('2017-12-05','mmm d, yyyy h:MMtt Z' ) -> "Dec 5, 2017 12:00am UTC"
 * @param {date} datetime
 * @param {String} format
 * @param {Boolean} UTC convert local time to UTC
 * @returns {String}
 */
export const formatDate = (datetime, format = 'mmm d, yyyy h:MMtt Z', utc = false) => {
  if (isString(datetime) && datetime.match(/\d+-\d+\d+ /)) {
    throw new Error(__('Invalid date'));
  }
  return dateFormat(datetime, format, utc);
};

/**
 * Formats milliseconds as timestamp (e.g. 01:02:03).
 * This takes durations longer than a day into account (e.g. two days would be 48:00:00).
 *
 * @param milliseconds
 * @returns {string}
 */
export const formatTime = (milliseconds) => {
  const seconds = Math.round(milliseconds / 1000);
  const absSeconds = Math.abs(seconds);

  const remainingSeconds = Math.floor(absSeconds) % 60;
  const remainingMinutes = Math.floor(absSeconds / 60) % 60;
  const hours = Math.floor(absSeconds / 60 / 60);

  let formattedTime = '';
  if (hours < 10) formattedTime += '0';
  formattedTime += `${hours}:`;
  if (remainingMinutes < 10) formattedTime += '0';
  formattedTime += `${remainingMinutes}:`;
  if (remainingSeconds < 10) formattedTime += '0';
  formattedTime += remainingSeconds;

  if (seconds < 0) {
    return `-${formattedTime}`;
  }
  return formattedTime;
};

/**
 * Port of ruby helper time_interval_in_words.
 *
 * @param  {Number} seconds
 * @return {String}
 */
export const timeIntervalInWords = (intervalInSeconds) => {
  const secondsInteger = parseInt(intervalInSeconds, 10);
  const minutes = Math.floor(secondsInteger / 60);
  const seconds = secondsInteger - minutes * 60;
  const secondsText = n__('%d second', '%d seconds', seconds);
  return minutes >= 1
    ? [n__('%d minute', '%d minutes', minutes), secondsText].join(' ')
    : secondsText;
};

/**
 * Accepts a timeObject (see parseSeconds) and returns a condensed string representation of it
 * (e.g. '1w 2d 3h 1m' or '1h 30m'). Zero value units are not included.
 * If the 'fullNameFormat' param is passed it returns a non condensed string eg '1 week 3 days'
 */
export const stringifyTime = (timeObject, fullNameFormat = false) => {
  const reducedTime = reduce(
    timeObject,
    (memo, unitValue, unitName) => {
      const isNonZero = Boolean(unitValue);

      if (fullNameFormat && isNonZero) {
        // Remove trailing 's' if unit value is singular
        const formattedUnitName = unitValue > 1 ? unitName : unitName.replace(/s$/, '');
        return `${memo} ${unitValue} ${formattedUnitName}`;
      }

      return isNonZero ? `${memo} ${unitValue}${unitName.charAt(0)}` : memo;
    },
    '',
  ).trim();
  return reducedTime.length ? reducedTime : '0m';
};

/**
 * Accepts seconds and returns a timeObject { weeks: #, days: #, hours: #, minutes: # }
 * Seconds can be negative or positive, zero or non-zero. Can be configured for any day
 * or week length.
 */
export const parseSeconds = (
  seconds,
  { daysPerWeek = 5, hoursPerDay = 8, limitToHours = false, limitToDays = false } = {},
) => {
  const DAYS_PER_WEEK = daysPerWeek;
  const HOURS_PER_DAY = hoursPerDay;
  const SECONDS_PER_MINUTE = 60;
  const MINUTES_PER_HOUR = 60;
  const MINUTES_PER_WEEK = DAYS_PER_WEEK * HOURS_PER_DAY * MINUTES_PER_HOUR;
  const MINUTES_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR;

  const timePeriodConstraints = {
    weeks: MINUTES_PER_WEEK,
    days: MINUTES_PER_DAY,
    hours: MINUTES_PER_HOUR,
    minutes: 1,
  };

  if (limitToDays || limitToHours) {
    timePeriodConstraints.weeks = 0;
  }

  if (limitToHours) {
    timePeriodConstraints.days = 0;
  }

  let unorderedMinutes = Math.abs(seconds / SECONDS_PER_MINUTE);

  return mapValues(timePeriodConstraints, (minutesPerPeriod) => {
    if (minutesPerPeriod === 0) {
      return 0;
    }

    const periodCount = Math.floor(unorderedMinutes / minutesPerPeriod);

    unorderedMinutes -= periodCount * minutesPerPeriod;

    return periodCount;
  });
};

/**
 * Pads given items with zeros to reach a length of 2 characters.
 *
 * @param  {...any} args Items to be padded.
 * @returns {Array<String>} Padded items.
 */
export const padWithZeros = (...args) => args.map((arg) => `${arg}`.padStart(2, '0'));

/**
 * This removes the timezone from an ISO date string.
 * This can be useful when populating date/time fields along with a distinct timezone selector, in
 * which case we'd want to ignore the timezone's offset when populating the date and time.
 *
 * Examples:
 * stripTimezoneFromISODate('2021-08-16T00:00:00.000-02:00') => '2021-08-16T00:00:00.000'
 * stripTimezoneFromISODate('2021-08-16T00:00:00.000Z') => '2021-08-16T00:00:00.000'
 *
 * @param {String} date The ISO date string representation.
 * @returns {String} The ISO date string without the timezone.
 */
export const stripTimezoneFromISODate = (date) => {
  if (Number.isNaN(Date.parse(date))) {
    return null;
  }
  return date.replace(/(Z|[+-]\d{2}:\d{2})$/, '');
};

/**
 * Extracts the year, month and day from a Date instance and returns them in an object.
 * For example:
 * dateToYearMonthDate(new Date('2021-08-16')) => { year: '2021', month: '08', day: '16' }
 *
 * @param {Date} date The date to be parsed
 * @returns {Object} An object containing the extracted year, month and day.
 */
export const dateToYearMonthDate = (date) => {
  if (!isDate(date)) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('Argument should be a Date instance');
  }
  const [month, day] = padWithZeros(date.getMonth() + 1, date.getDate());
  return {
    year: `${date.getFullYear()}`,
    month,
    day,
  };
};

/**
 * Extracts the hours and minutes from a string representing a time.
 * For example:
 * timeToHoursMinutes('12:46') => { hours: '12', minutes: '46' }
 *
 * @param {String} time The time to be parsed in the form HH:MM.
 * @returns {Object} An object containing the hours and minutes.
 */
export const timeToHoursMinutes = (time = '') => {
  if (!time || !time.match(/\d{1,2}:\d{1,2}/)) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('Invalid time provided');
  }
  const [hours, minutes] = padWithZeros(...time.split(':'));
  return { hours, minutes };
};

/**
 * This combines a date and a time and returns the computed Date's ISO string representation.
 *
 * @param {Date} date Date object representing the base date.
 * @param {String} time String representing the time to be used, in the form HH:MM.
 * @param {String} offset An optional Date-compatible offset.
 * @returns {String} The combined Date's ISO string representation.
 */
export const dateAndTimeToISOString = (date, time, offset = '') => {
  const { year, month, day } = dateToYearMonthDate(date);
  const { hours, minutes } = timeToHoursMinutes(time);
  const dateString = `${year}-${month}-${day}T${hours}:${minutes}:00.000${offset || 'Z'}`;
  if (Number.isNaN(Date.parse(dateString))) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('Could not initialize date');
  }
  return dateString;
};

/**
 * Converts a Date instance to time input-compatible value consisting in a 2-digits hours and
 * minutes, separated by a semi-colon, in the 24-hours format.
 *
 * @param {Date} date Date to be converted
 * @returns {String} time input-compatible string in the form HH:MM.
 */
export const dateToTimeInputValue = (date) => {
  if (!isDate(date)) {
    // eslint-disable-next-line @gitlab/require-i18n-strings
    throw new Error('Argument should be a Date instance');
  }
  return date.toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
};

export const formatTimeAsSummary = ({ seconds, hours, days, minutes, weeks, months }) => {
  if (months) {
    const value = roundToNearestHalf(months);
    return sprintf(
      n__('ValueStreamAnalytics|%{value} month', 'ValueStreamAnalytics|%{value} months', value),
      {
        value,
      },
    );
  }
  if (weeks) {
    const value = roundToNearestHalf(weeks);
    return sprintf(
      n__('ValueStreamAnalytics|%{value} week', 'ValueStreamAnalytics|%{value} weeks', value),
      {
        value,
      },
    );
  }
  if (days) {
    const value = roundToNearestHalf(days);
    return sprintf(
      n__('ValueStreamAnalytics|%{value} day', 'ValueStreamAnalytics|%{value} days', value),
      {
        value,
      },
    );
  }
  if (hours) {
    return sprintf(
      n__('ValueStreamAnalytics|%{value} hour', 'ValueStreamAnalytics|%{value} hours', hours),
      {
        value: hours,
      },
    );
  }
  if (minutes) {
    return sprintf(
      n__('ValueStreamAnalytics|%{value} minute', 'ValueStreamAnalytics|%{value} minutes', minutes),
      {
        value: minutes,
      },
    );
  }
  if (seconds) {
    return unescape(sanitize(s__('ValueStreamAnalytics|&lt;1 minute'), { ALLOWED_TAGS: [] }));
  }
  return '-';
};

/**
 * Converts a numeric utc offset in seconds to +/- hours
 * ie -32400 => -9 hours
 * ie -12600 => -3.5 hours
 *
 * @param {Number} offset UTC offset in seconds as a integer
 *
 * @return {String} the + or - offset in hours, e.g. `-10`, ` 0`, `+4`
 */
export const formatUtcOffset = (offset) => {
  const parsed = parseInt(offset, 10);
  if (Number.isNaN(parsed) || parsed === 0) {
    return ` 0`;
  }
  const prefix = offset > 0 ? '+' : '-';
  return `${prefix}${Math.abs(offset / 3600)}`;
};

/**
 * Returns formatted timezone
 *
 * @param {Object} timezone item with offset and name
 * @returns {String} the UTC timezone with the offset, e.g. `[UTC+2] Berlin, [UTC 0] London`
 */
export const formatTimezone = ({ offset, name }) => `[UTC${formatUtcOffset(offset)}] ${name}`;

/**
 * Returns humanized string showing date range from provided start and due dates.
 *
 * @param {Date} startDate
 * @param {Date} dueDate
 * @returns
 */
export const humanTimeframe = (startDate, dueDate) => {
  const start = startDate ? parsePikadayDate(startDate) : null;
  const due = dueDate ? parsePikadayDate(dueDate) : null;

  if (startDate && dueDate) {
    const startDateInWords = dateInWords(start, true, start.getFullYear() === due.getFullYear());
    const dueDateInWords = dateInWords(due, true);

    return sprintf(__('%{startDate} – %{dueDate}'), {
      startDate: startDateInWords,
      dueDate: dueDateInWords,
    });
  }
  if (startDate && !dueDate) {
    return sprintf(__('%{startDate} – No due date'), {
      startDate: dateInWords(start, true, false),
    });
  }
  if (!startDate && dueDate) {
    return sprintf(__('No start date – %{dueDate}'), {
      dueDate: dateInWords(due, true, false),
    });
  }
  return '';
};
