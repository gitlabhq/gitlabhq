import $ from 'jquery';
import _ from 'underscore';
import * as timeago from 'timeago.js';
import dateFormat from 'dateformat';
import { languageCode, s__, __, n__ } from '../../locale';

window.timeago = timeago;

/**
 * This method allows you to create new Date instance from existing
 * date instance without keeping the reference.
 *
 * @param {Date} date
 */
export const newDate = date => (date instanceof Date ? new Date(date.getTime()) : new Date());

/**
 * Returns i18n month names array.
 * If `abbreviated` is provided, returns abbreviated
 * name.
 *
 * @param {Boolean} abbreviated
 */
export const getMonthNames = abbreviated => {
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

export const pad = (val, len = 2) => `0${val}`.slice(-len);

/**
 * Given a date object returns the day of the week in English
 * @param {date} date
 * @returns {String}
 */
export const getDayName = date =>
  [
    __('Sunday'),
    __('Monday'),
    __('Tuesday'),
    __('Wednesday'),
    __('Thursday'),
    __('Friday'),
    __('Saturday'),
  ][date.getDay()];

/**
 * @example
 * dateFormat('2017-12-05','mmm d, yyyy h:MMtt Z' ) -> "Dec 5, 2017 12:00am GMT+0000"
 * @param {date} datetime
 * @returns {String}
 */
export const formatDate = (datetime, format = 'mmm d, yyyy h:MMtt Z') => {
  if (_.isString(datetime) && datetime.match(/\d+-\d+\d+ /)) {
    throw new Error(__('Invalid date'));
  }
  return dateFormat(datetime, format);
};

/**
 * Timeago uses underscores instead of dashes to separate language from country code.
 *
 * see https://github.com/hustcc/timeago.js/tree/v3.0.0/locales
 */
const timeagoLanguageCode = languageCode().replace(/-/g, '_');

/**
 * Registers timeago locales
 */
const memoizedLocaleRemaining = () => {
  const cache = [];

  const timeAgoLocaleRemaining = [
    () => [s__('Timeago|just now'), s__('Timeago|right now')],
    () => [s__('Timeago|just now'), s__('Timeago|%s seconds remaining')],
    () => [s__('Timeago|1 minute ago'), s__('Timeago|1 minute remaining')],
    () => [s__('Timeago|%s minutes ago'), s__('Timeago|%s minutes remaining')],
    () => [s__('Timeago|1 hour ago'), s__('Timeago|1 hour remaining')],
    () => [s__('Timeago|%s hours ago'), s__('Timeago|%s hours remaining')],
    () => [s__('Timeago|1 day ago'), s__('Timeago|1 day remaining')],
    () => [s__('Timeago|%s days ago'), s__('Timeago|%s days remaining')],
    () => [s__('Timeago|1 week ago'), s__('Timeago|1 week remaining')],
    () => [s__('Timeago|%s weeks ago'), s__('Timeago|%s weeks remaining')],
    () => [s__('Timeago|1 month ago'), s__('Timeago|1 month remaining')],
    () => [s__('Timeago|%s months ago'), s__('Timeago|%s months remaining')],
    () => [s__('Timeago|1 year ago'), s__('Timeago|1 year remaining')],
    () => [s__('Timeago|%s years ago'), s__('Timeago|%s years remaining')],
  ];

  return (number, index) => {
    if (cache[index]) {
      return cache[index];
    }
    cache[index] = timeAgoLocaleRemaining[index] && timeAgoLocaleRemaining[index]();
    return cache[index];
  };
};

const memoizedLocale = () => {
  const cache = [];

  const timeAgoLocale = [
    () => [s__('Timeago|just now'), s__('Timeago|right now')],
    () => [s__('Timeago|just now'), s__('Timeago|in %s seconds')],
    () => [s__('Timeago|1 minute ago'), s__('Timeago|in 1 minute')],
    () => [s__('Timeago|%s minutes ago'), s__('Timeago|in %s minutes')],
    () => [s__('Timeago|1 hour ago'), s__('Timeago|in 1 hour')],
    () => [s__('Timeago|%s hours ago'), s__('Timeago|in %s hours')],
    () => [s__('Timeago|1 day ago'), s__('Timeago|in 1 day')],
    () => [s__('Timeago|%s days ago'), s__('Timeago|in %s days')],
    () => [s__('Timeago|1 week ago'), s__('Timeago|in 1 week')],
    () => [s__('Timeago|%s weeks ago'), s__('Timeago|in %s weeks')],
    () => [s__('Timeago|1 month ago'), s__('Timeago|in 1 month')],
    () => [s__('Timeago|%s months ago'), s__('Timeago|in %s months')],
    () => [s__('Timeago|1 year ago'), s__('Timeago|in 1 year')],
    () => [s__('Timeago|%s years ago'), s__('Timeago|in %s years')],
  ];

  return (number, index) => {
    if (cache[index]) {
      return cache[index];
    }
    cache[index] = timeAgoLocale[index] && timeAgoLocale[index]();
    return cache[index];
  };
};

timeago.register(timeagoLanguageCode, memoizedLocale());
timeago.register(`${timeagoLanguageCode}-remaining`, memoizedLocaleRemaining());

export const getTimeago = () => timeago;

/**
 * For the given elements, sets a tooltip with a formatted date.
 * @param {JQuery} $timeagoEls
 * @param {Boolean} setTimeago
 */
export const localTimeAgo = ($timeagoEls, setTimeago = true) => {
  $timeagoEls.each((i, el) => {
    $(el).text(timeago.format($(el).attr('datetime'), timeagoLanguageCode));
  });

  if (!setTimeago) {
    return;
  }

  function addTimeAgoTooltip() {
    $timeagoEls.each((i, el) => {
      // Recreate with custom template
      $(el).tooltip({
        template:
          '<div class="tooltip local-timeago" role="tooltip"><div class="arrow"></div><div class="tooltip-inner"></div></div>',
      });
    });
  }

  requestIdleCallback(addTimeAgoTooltip);
};

/**
 * Returns remaining or passed time over the given time.
 * @param {*} time
 * @param {*} expiredLabel
 */
export const timeFor = (time, expiredLabel) => {
  if (!time) {
    return '';
  }
  if (new Date(time) < new Date()) {
    return expiredLabel || s__('Timeago|Past due');
  }
  return timeago.format(time, `${timeagoLanguageCode}-remaining`).trim();
};

export const getDayDifference = (a, b) => {
  const millisecondsPerDay = 1000 * 60 * 60 * 24;
  const date1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
  const date2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());

  return Math.floor((date2 - date1) / millisecondsPerDay);
};

/**
 * Port of ruby helper time_interval_in_words.
 *
 * @param  {Number} seconds
 * @return {String}
 */
export const timeIntervalInWords = intervalInSeconds => {
  const secondsInteger = parseInt(intervalInSeconds, 10);
  const minutes = Math.floor(secondsInteger / 60);
  const seconds = secondsInteger - minutes * 60;
  const secondsText = n__('%d second', '%d seconds', seconds);
  return minutes >= 1
    ? [n__('%d minute', '%d minutes', minutes), secondsText].join(' ')
    : secondsText;
};

export const dateInWords = (date, abbreviated = false, hideYear = false) => {
  if (!date) return date;

  const month = date.getMonth();
  const year = date.getFullYear();

  const monthNames = [
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
  const monthNamesAbbr = [
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

  const monthName = abbreviated ? monthNamesAbbr[month] : monthNames[month];

  if (hideYear) {
    return `${monthName} ${date.getDate()}`;
  }

  return `${monthName} ${date.getDate()}, ${year}`;
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

/**
 * Returns number of days in a month for provided date.
 * courtesy: https://stacko(verflow.com/a/1185804/414749
 *
 * @param {Date} date
 */
export const totalDaysInMonth = date => {
  if (!date) {
    return 0;
  }
  return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
};

/**
 * Returns number of days in a quarter from provided
 * months array.
 *
 * @param {Array} quarter
 */
export const totalDaysInQuarter = quarter =>
  quarter.reduce((acc, month) => acc + totalDaysInMonth(month), 0);

/**
 * Returns list of Dates referring to Sundays of the month
 * based on provided date
 *
 * @param {Date} date
 */
export const getSundays = date => {
  if (!date) {
    return [];
  }

  const daysToSunday = [
    __('Saturday'),
    __('Friday'),
    __('Thursday'),
    __('Wednesday'),
    __('Tuesday'),
    __('Monday'),
    __('Sunday'),
  ];

  const month = date.getMonth();
  const year = date.getFullYear();
  const sundays = [];
  const dateOfMonth = new Date(year, month, 1);

  while (dateOfMonth.getMonth() === month) {
    const dayName = getDayName(dateOfMonth);
    if (dayName === __('Sunday')) {
      sundays.push(new Date(dateOfMonth.getTime()));
    }

    const daysUntilNextSunday = daysToSunday.indexOf(dayName) + 1;
    dateOfMonth.setDate(dateOfMonth.getDate() + daysUntilNextSunday);
  }

  return sundays;
};

/**
 * Returns list of Dates representing a timeframe of months from startDate and length
 * This method also supports going back in time when `length` is negative number
 *
 * @param {Date} initialStartDate
 * @param {Number} length
 */
export const getTimeframeWindowFrom = (initialStartDate, length) => {
  if (!(initialStartDate instanceof Date) || !length) {
    return [];
  }

  const startDate = newDate(initialStartDate);
  const moveMonthBy = length > 0 ? 1 : -1;

  startDate.setDate(1);
  startDate.setHours(0, 0, 0, 0);

  // Iterate and set date for the size of length
  // and push date reference to timeframe list
  const timeframe = new Array(Math.abs(length)).fill().map(() => {
    const currentMonth = startDate.getTime();
    startDate.setMonth(startDate.getMonth() + moveMonthBy);
    return new Date(currentMonth);
  });

  // Change date of last timeframe item to last date of the month
  // when length is positive
  if (length > 0) {
    timeframe[timeframe.length - 1].setDate(totalDaysInMonth(timeframe[timeframe.length - 1]));
  }

  return timeframe;
};

/**
 * Returns count of day within current quarter from provided date
 * and array of months for the quarter
 *
 * Eg;
 *   If date is 15 Feb 2018
 *   and quarter is [Jan, Feb, Mar]
 *
 *   Then 15th Feb is 46th day of the quarter
 *   Where 31 (days in Jan) + 15 (date of Feb).
 *
 * @param {Date} date
 * @param {Array} quarter
 */
export const dayInQuarter = (date, quarter) => {
  const dateValues = {
    date: date.getDate(),
    month: date.getMonth(),
  };

  return quarter.reduce((acc, month) => {
    if (dateValues.month > month.getMonth()) {
      return acc + totalDaysInMonth(month);
    } else if (dateValues.month === month.getMonth()) {
      return acc + dateValues.date;
    }
    return acc + 0;
  }, 0);
};

window.gl = window.gl || {};
window.gl.utils = {
  ...(window.gl.utils || {}),
  getTimeago,
  localTimeAgo,
};

/**
 * Formats milliseconds as timestamp (e.g. 01:02:03).
 * This takes durations longer than a day into account (e.g. two days would be 48:00:00).
 *
 * @param milliseconds
 * @returns {string}
 */
export const formatTime = milliseconds => {
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
 * Formats dates in Pickaday
 * @param {String} dateString Date in yyyy-mm-dd format
 * @return {Date} UTC format
 */
export const parsePikadayDate = dateString => {
  const parts = dateString.split('-');
  const year = parseInt(parts[0], 10);
  const month = parseInt(parts[1] - 1, 10);
  const day = parseInt(parts[2], 10);

  return new Date(year, month, day);
};

/**
 * Used `onSelect` method in pickaday
 * @param {Date} date UTC format
 * @return {String} Date formatted in yyyy-mm-dd
 */
export const pikadayToString = date => {
  const day = pad(date.getDate());
  const month = pad(date.getMonth() + 1);
  const year = date.getFullYear();

  return `${year}-${month}-${day}`;
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

  return _.mapObject(timePeriodConstraints, minutesPerPeriod => {
    if (minutesPerPeriod === 0) {
      return 0;
    }

    const periodCount = Math.floor(unorderedMinutes / minutesPerPeriod);

    unorderedMinutes -= periodCount * minutesPerPeriod;

    return periodCount;
  });
};

/**
 * Accepts a timeObject (see parseSeconds) and returns a condensed string representation of it
 * (e.g. '1w 2d 3h 1m' or '1h 30m'). Zero value units are not included.
 * If the 'fullNameFormat' param is passed it returns a non condensed string eg '1 week 3 days'
 */
export const stringifyTime = (timeObject, fullNameFormat = false) => {
  const reducedTime = _.reduce(
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
 * Calculates the milliseconds between now and a given date string.
 * The result cannot become negative.
 *
 * @param endDate date string that the time difference is calculated for
 * @return {Number} number of milliseconds remaining until the given date
 */
export const calculateRemainingMilliseconds = endDate => {
  const remainingMilliseconds = new Date(endDate).getTime() - Date.now();
  return Math.max(remainingMilliseconds, 0);
};

/**
 * Subtracts a given number of days from a given date and returns the new date.
 *
 * @param {Date} date the date that we will substract days from
 * @param {Number} daysInPast number of days that are subtracted from a given date
 * @returns {Date} Date in past as Date object
 */
export const getDateInPast = (date, daysInPast) =>
  new Date(newDate(date).setDate(date.getDate() - daysInPast));

/**
 * Adds a given number of days to a given date and returns the new date.
 *
 * @param {Date} date the date that we will add days to
 * @param {Number} daysInFuture number of days that are added to a given date
 * @returns {Date} Date in future as Date object
 */
export const getDateInFuture = (date, daysInFuture) =>
  new Date(newDate(date).setDate(date.getDate() + daysInFuture));

/*
 * Appending T00:00:00 makes JS assume local time and prevents it from shifting the date
 * to match the user's time zone. We want to display the date in server time for now, to
 * be consistent with the "edit issue -> due date" UI.
 */

export const newDateAsLocaleTime = date => {
  const suffix = 'T00:00:00';
  return new Date(`${date}${suffix}`);
};

export const beginOfDayTime = 'T00:00:00Z';
export const endOfDayTime = 'T23:59:59Z';

/**
 * @param {Date} d1
 * @param {Date} d2
 * @param {Function} formatter
 * @return {Any[]} an array of formatted dates between 2 given dates (including start&end date)
 */
export const getDatesInRange = (d1, d2, formatter = x => x) => {
  if (!(d1 instanceof Date) || !(d2 instanceof Date)) {
    return [];
  }
  let startDate = d1.getTime();
  const endDate = d2.getTime();
  const oneDay = 24 * 3600 * 1000;
  const range = [d1];

  while (startDate < endDate) {
    startDate += oneDay;
    range.push(new Date(startDate));
  }

  return range.map(formatter);
};

/**
 * Converts the supplied number of seconds to milliseconds.
 *
 * @param {Number} seconds
 * @return {Number} number of milliseconds
 */
export const secondsToMilliseconds = seconds => seconds * 1000;

/**
 * Converts the supplied number of seconds to days.
 *
 * @param {Number} seconds
 * @return {Number} number of days
 */
export const secondsToDays = seconds => Math.round(seconds / 86400);

/**
 * Returns the date after the date provided
 *
 * @param {Date} date the initial date
 * @return {Date} the date following the date provided
 */
export const dayAfter = date => new Date(newDate(date).setDate(date.getDate() + 1));

/**
 * Mimics the behaviour of the rails distance_of_time_in_words function
 * https://api.rubyonrails.org/v6.0.1/classes/ActionView/Helpers/DateHelper.html#method-i-distance_of_time_in_words
 * 0 < -> 29 secs                                         => less than a minute
 * 30 secs < -> 1 min, 29 secs                            => 1 minute
 * 1 min, 30 secs < -> 44 mins, 29 secs                   => [2..44] minutes
 * 44 mins, 30 secs < -> 89 mins, 29 secs                 => about 1 hour
 * 89 mins, 30 secs < -> 23 hrs, 59 mins, 29 secs         => about[2..24]hours
 * 23 hrs, 59 mins, 30 secs < -> 41 hrs, 59 mins, 29 secs => 1 day
 * 41 hrs, 59 mins, 30 secs                               => x days
 *
 * @param {Number} seconds
 * @return {String} approximated time
 */
export const approximateDuration = (seconds = 0) => {
  if (!_.isNumber(seconds) || seconds < 0) {
    return '';
  }

  const ONE_MINUTE_LIMIT = 90; // 1 minute 30s
  const MINUTES_LIMIT = 2670; // 44 minutes 30s
  const ONE_HOUR_LIMIT = 5370; // 89 minutes 30s
  const HOURS_LIMIT = 86370; // 23 hours 59 minutes 30s
  const ONE_DAY_LIMIT = 151170; // 41 hours 59 minutes 30s

  const { days = 0, hours = 0, minutes = 0 } = parseSeconds(seconds, {
    daysPerWeek: 7,
    hoursPerDay: 24,
    limitToDays: true,
  });

  if (seconds < 30) {
    return __('less than a minute');
  } else if (seconds < MINUTES_LIMIT) {
    return n__('1 minute', '%d minutes', seconds < ONE_MINUTE_LIMIT ? 1 : minutes);
  } else if (seconds < HOURS_LIMIT) {
    return n__('about 1 hour', 'about %d hours', seconds < ONE_HOUR_LIMIT ? 1 : hours);
  }
  return n__('1 day', '%d days', seconds < ONE_DAY_LIMIT ? 1 : days);
};
