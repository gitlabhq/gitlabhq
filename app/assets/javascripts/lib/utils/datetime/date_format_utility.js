import dateFormat from 'dateformat';
import { isString, mapValues, reduce } from 'lodash';
import { s__, n__, __ } from '../../../locale';

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
      s__('Jan'),
      s__('Feb'),
      s__('Mar'),
      s__('Apr'),
      s__('May'),
      s__('Jun'),
      s__('Jul'),
      s__('Aug'),
      s__('Sep'),
      s__('Oct'),
      s__('Nov'),
      s__('Dec'),
    ];
  }
  return [
    s__('January'),
    s__('February'),
    s__('March'),
    s__('April'),
    s__('May'),
    s__('June'),
    s__('July'),
    s__('August'),
    s__('September'),
    s__('October'),
    s__('November'),
    s__('December'),
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
  } else if (intervalInSeconds < 3600 /* = 1 hour */) {
    const minutes = Math.round(intervalInSeconds / 6) / 10;
    return n__('%d minute', '%d minutes', minutes);
  } else if (intervalInSeconds < 86400 /* = 1 day */) {
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
  const remainingSeconds = Math.floor(milliseconds / 1000) % 60;
  const remainingMinutes = Math.floor(milliseconds / 1000 / 60) % 60;
  const remainingHours = Math.floor(milliseconds / 1000 / 60 / 60);
  let formattedTime = '';
  if (remainingHours < 10) formattedTime += '0';
  formattedTime += `${remainingHours}:`;
  if (remainingMinutes < 10) formattedTime += '0';
  formattedTime += `${remainingMinutes}:`;
  if (remainingSeconds < 10) formattedTime += '0';
  formattedTime += remainingSeconds;
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
        // Remove traling 's' if unit value is singular
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
