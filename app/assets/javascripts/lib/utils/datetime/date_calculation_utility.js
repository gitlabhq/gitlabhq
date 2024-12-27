import { isNumber } from 'lodash';
import dateformat from '~/lib/dateformat';
import { __, n__ } from '~/locale';
import { getDayName, parseSeconds } from './date_format_utility';

const DAYS_IN_WEEK = 7;

export const DATE_ONLY_REGEX = /^\d{4}-\d{2}-\d{2}$/; // yyyy-mm-dd format
export const SECONDS_IN_DAY = 86400;
export const MILLISECONDS_IN_DAY = 24 * 60 * 60 * 1000;

/**
 * Creates a new `Date` object.
 * If a `Date` object is provided, then it is cloned.
 *
 * This function fixes a bug with the `Date` constructor where
 * passing a date-only string results in a date 1 day behind
 * for timezones that are behind UTC.
 *
 * From https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date:
 *
 * > When the time zone offset is absent, **date-only forms are
 * interpreted as a UTC time and date-time forms are interpreted
 * as local time**. This is due to a historical spec error that
 * was not consistent with ISO 8601 but could not be changed
 * due to web compatibility.
 *
 * For example, the bug `new Date('2020-02-02')` results in
 * `Sat Feb 01 2020 16:00:00 GMT-0800 (Pacific Standard Time)`
 * for UTC-8 timezone.
 *
 * With this function, `newDate('2020-02-02')` results in
 * `Wed Feb 02 2022 00:00:00 GMT-0800 (Pacific Standard Time)`
 * for UTC-8 timezone.
 *
 * @param {string|number|Date} date
 * @returns {Date|null|undefined} A Date object in local time
 */
export const newDate = (date) => {
  if (date === null) {
    return null;
  }
  if (date === undefined) {
    return undefined;
  }
  // Fix historical bug so we return a local time for `yyyy-mm-dd` date-only strings
  if (typeof date === 'string' && DATE_ONLY_REGEX.test(date)) {
    const parts = date.split('-');
    const year = parseInt(parts[0], 10);
    const month = parseInt(parts[1], 10) - 1; // month is 0-indexed
    const day = parseInt(parts[2], 10);
    return new Date(year, month, day);
  }
  return new Date(date);
};

/**
 * This method allows you to create new Date instance from existing
 * date instance without keeping the reference.
 *
 * @param {Date} date
 */
export const cloneDate = (date) => (date instanceof Date ? new Date(date.getTime()) : new Date());

/**
 * Returns number of days in a month for provided date.
 * courtesy: https://stacko(verflow.com/a/1185804/414749
 *
 * @param {Date} date
 */
export const totalDaysInMonth = (date) => {
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
export const totalDaysInQuarter = (quarter) =>
  quarter.reduce((acc, month) => acc + totalDaysInMonth(month), 0);

/**
 * Returns list of Dates referring to Sundays of the month
 * based on provided date
 *
 * @param {Date} date
 */
export const getSundays = (date) => {
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

  const startDate = cloneDate(initialStartDate);
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
    }
    if (dateValues.month === month.getMonth()) {
      return acc + dateValues.date;
    }
    return acc + 0;
  }, 0);
};

export const millisecondsPerDay = 1000 * 60 * 60 * 24;

/**
 * Calculates the number of days between 2 specified dates, excluding the current date
 *
 * @param {Date} startDate the earlier date that we will substract from the end date
 * @param {Date} endDate the last date in the range
 * @return {Number} number of days in between
 */
export const getDayDifference = (startDate, endDate) => {
  const date1 = Date.UTC(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
  const date2 = Date.UTC(endDate.getFullYear(), endDate.getMonth(), endDate.getDate());

  return Math.floor((date2 - date1) / millisecondsPerDay);
};

/**
 * Calculates the milliseconds between now and a given date string.
 * The result cannot become negative.
 *
 * @param endDate date string that the time difference is calculated for
 * @return {Number} number of milliseconds remaining until the given date
 */
export const calculateRemainingMilliseconds = (endDate) => {
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
  new Date(cloneDate(date).setDate(date.getDate() - daysInPast));

/**
 * Adds a given number of days to a given date and returns the new date.
 *
 * @param {Date} date the date that we will add days to
 * @param {Number} daysInFuture number of days that are added to a given date
 * @returns {Date} Date in future as Date object
 */
export const getDateInFuture = (date, daysInFuture) =>
  new Date(cloneDate(date).setDate(date.getDate() + daysInFuture));

/**
 * Checks if a given date-instance was created with a valid date
 *
 * @param  {Date} date
 * @returns boolean
 */
export const isValidDate = (date) => date instanceof Date && !Number.isNaN(date.getTime());

export const beginOfDayTime = 'T00:00:00Z';
export const endOfDayTime = 'T23:59:59Z';

/**
 * @param {Date} d1
 * @param {Date} d2
 * @param {Function} formatter
 * @return {Any[]} an array of formatted dates between 2 given dates (including start&end date)
 */
export const getDatesInRange = (d1, d2, formatter = (x) => x) => {
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
export const secondsToMilliseconds = (seconds) => seconds * 1000;

/**
 * Converts the supplied number of seconds to days.
 *
 * @param {Number} seconds
 * @return {Number} number of days
 */
export const secondsToDays = (seconds) => Math.round(seconds / 86400);

/**
 * Returns the date `n` seconds after the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfSeconds number of seconds after
 * @return {Date} A `Date` object `n` seconds after the provided `Date`
 */
export const nSecondsAfter = (date, numberOfSeconds) =>
  new Date(date.getTime() + numberOfSeconds * 1000);

/**
 * Returns the date `n` seconds before the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfSeconds number of seconds before
 * @return {Date} A `Date` object `n` seconds before the provided `Date`
 */
export const nSecondsBefore = (date, numberOfSeconds) => nSecondsAfter(date, -numberOfSeconds);

/**
 * Returns the date `n` hours after the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfHours number of hours after
 * @return {Date} A `Date` object `n` hours after the provided `Date`
 */
export const nHoursAfter = (date, numberOfHours) => {
  const clone = cloneDate(date);

  clone.setHours(date.getHours() + numberOfHours);

  return clone;
};

/**
 * Returns the date `n` days after the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfDays number of days after
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 *
 * @return {Date} A `Date` object `n` days after the provided `Date`
 */
export const nDaysAfter = (date, numberOfDays, { utc = false } = {}) => {
  const clone = cloneDate(date);

  const cloneValue = utc
    ? clone.setUTCDate(date.getUTCDate() + numberOfDays)
    : clone.setDate(date.getDate() + numberOfDays);

  return new Date(cloneValue);
};

/**
 * Returns the date `n` days before the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfDays number of days before
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 * @return {Date} A `Date` object `n` days before the provided `Date`
 */
export const nDaysBefore = (date, numberOfDays, options) =>
  nDaysAfter(date, -numberOfDays, options);

/**
 * Returns the date `n` months after the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfMonths number of months after
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 *
 * @return {Date} A `Date` object `n` months after the provided `Date`
 */
export const nMonthsAfter = (date, numberOfMonths, { utc = false } = {}) => {
  const clone = cloneDate(date);

  const cloneValue = utc
    ? clone.setUTCMonth(date.getUTCMonth() + numberOfMonths)
    : clone.setMonth(date.getMonth() + numberOfMonths);

  return new Date(cloneValue);
};

/**
 * Returns the date `n` months before the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfMonths number of months before
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 *
 * @return {Date} A `Date` object `n` months before the provided `Date`
 */
export const nMonthsBefore = (date, numberOfMonths, options) =>
  nMonthsAfter(date, -numberOfMonths, options);

/**
 * Returns the date `n` weeks after the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfWeeks number of weeks after
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 *
 * @return {Date} A `Date` object `n` weeks after the provided `Date`
 */
export const nWeeksAfter = (date, numberOfWeeks, options) =>
  nDaysAfter(date, DAYS_IN_WEEK * numberOfWeeks, options);

/**
 * Returns the date `n` weeks before the date provided
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfWeeks number of weeks before
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 *
 * @return {Date} A `Date` object `n` weeks before the provided `Date`
 */
export const nWeeksBefore = (date, numberOfWeeks, options) =>
  nWeeksAfter(date, -numberOfWeeks, options);

/**
 * Returns the date `n` years after the date provided.
 * When Feb 29 is the specified date, the default behaviour is to return March 1.
 * But to align with the equivalent rails code, moment JS and datefns we should return Feb 28 instead.
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfYears number of years after
 * @return {Date} A `Date` object `n` years after the provided `Date`
 */
export const nYearsAfter = (date, numberOfYears) => {
  const clone = cloneDate(date);
  clone.setUTCMonth(clone.getUTCMonth());

  // If the date we are calculating from is Feb 29, return the equivalent result for Feb 28
  if (clone.getUTCMonth() === 1 && clone.getUTCDate() === 29) {
    clone.setUTCDate(28);
  } else {
    clone.setUTCDate(clone.getUTCDate());
  }

  clone.setUTCFullYear(clone.getUTCFullYear() + numberOfYears);
  return clone;
};

/**
 * Returns the date `n` years before the date provided.
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfYears number of years before
 * @return {Date} A `Date` object `n` years before the provided `Date`
 */
export const nYearsBefore = (date, numberOfYears) => nYearsAfter(date, -numberOfYears);

/**
 * Returns the date after the date provided
 *
 * @param {Date} date the initial date
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC dates.
 * This will cause Daylight Saving Time to be ignored. Defaults to `false`
 * if not provided, which causes the calculation to be performed in the
 * user's timezone.
 *
 * @return {Date} the date following the date provided
 */
export const dayAfter = (date, options) => nDaysAfter(date, 1, options);

/**
 * A utility function which computes the difference in seconds
 * between 2 dates.
 *
 * @param {Date} startDate the start date
 * @param {Date} endDate the end date
 *
 * @return {Int} the difference in seconds
 */
export const differenceInSeconds = (startDate, endDate) => {
  return (endDate.getTime() - startDate.getTime()) / 1000;
};

export const differenceInMinutes = (startDate, endDate) => {
  return Math.ceil(differenceInSeconds(startDate, endDate) / 60);
};

/**
 * A utility function which computes the difference in months
 * between 2 dates.
 *
 * @param {Date} startDate the start date
 * @param {Date} endDate the end date
 *
 * @return {Int} the difference in months
 */
export const differenceInMonths = (startDate, endDate) => {
  const yearDiff = endDate.getYear() - startDate.getYear();
  const monthDiff = endDate.getMonth() - startDate.getMonth();
  return monthDiff + 12 * yearDiff;
};

/**
 * A utility function which computes the difference in milliseconds
 * between 2 dates.
 *
 * @param {Date|Int} startDate the start date. Can be either a date object or a unix timestamp.
 * @param {Date|Int} endDate the end date. Can be either a date object or a unix timestamp. Defaults to now.
 *
 * @return {Int} the difference in milliseconds
 */
export const differenceInMilliseconds = (startDate, endDate = Date.now()) => {
  const startDateInMS = startDate instanceof Date ? startDate.getTime() : startDate;
  const endDateInMS = endDate instanceof Date ? endDate.getTime() : endDate;
  return endDateInMS - startDateInMS;
};

/**
 * A utility which returns a new date at the first day of the month for any given date.
 *
 * @param {Date} date
 *
 * @return {Date} the date at the first day of the month
 */
export const dateAtFirstDayOfMonth = (date) => new Date(cloneDate(date).setDate(1));

/**
 * A utility function which checks if two dates match.
 *
 * @param {Date|Int} date1 Can be either a date object or a unix timestamp.
 * @param {Date|Int} date2 Can be either a date object or a unix timestamp.
 *
 * @return {Boolean} true if the dates match
 */
export const datesMatch = (date1, date2) => differenceInMilliseconds(date1, date2) === 0;

/**
 * Mimics the behaviour of the rails distance_of_time_in_words function
 * https://api.rubyonrails.org/classes/ActionView/Helpers/DateHelper.html#method-i-distance_of_time_in_words
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
  if (!isNumber(seconds) || seconds < 0) {
    return '';
  }

  const ONE_MINUTE_LIMIT = 90; // 1 minute 30s
  const MINUTES_LIMIT = 2670; // 44 minutes 30s
  const ONE_HOUR_LIMIT = 5370; // 89 minutes 30s
  const HOURS_LIMIT = 86370; // 23 hours 59 minutes 30s
  const ONE_DAY_LIMIT = 151170; // 41 hours 59 minutes 30s

  const {
    days = 0,
    hours = 0,
    minutes = 0,
  } = parseSeconds(seconds, {
    daysPerWeek: 7,
    hoursPerDay: 24,
    limitToDays: true,
  });

  if (seconds < 30) {
    return __('less than a minute');
  }
  if (seconds < MINUTES_LIMIT) {
    return n__('1 minute', '%d minutes', seconds < ONE_MINUTE_LIMIT ? 1 : minutes);
  }
  if (seconds < HOURS_LIMIT) {
    return n__('about 1 hour', 'about %d hours', seconds < ONE_HOUR_LIMIT ? 1 : hours);
  }
  return n__('1 day', '%d days', seconds < ONE_DAY_LIMIT ? 1 : days);
};

/**
 * A utility function which computes a formatted 24 hour
 * time string from a positive int in the range 0 - 24.
 *
 * @param {Int} time a positive Int between 0 and 24
 *
 * @returns {String} formatted 24 hour time String
 */
export const format24HourTimeStringFromInt = (time) => {
  if (!Number.isInteger(time) || time < 0 || time > 24) {
    return '';
  }

  const formatted24HourString = time > 9 ? `${time}:00` : `0${time}:00`;
  return formatted24HourString;
};

/**
 * A utility function that checks that the date is today
 *
 * @param {Date} date
 *
 * @return {Boolean} true if provided date is today
 */
export const isToday = (date) => {
  const today = new Date();
  return (
    date.getDate() === today.getDate() &&
    date.getMonth() === today.getMonth() &&
    date.getFullYear() === today.getFullYear()
  );
};

/**
 * Checks whether the date is in the past.
 *
 * @param {Date} date
 * @return {Boolean} Returns true if the date falls before today, otherwise false.
 */
export const isInPast = (date) => !isToday(date) && differenceInMilliseconds(date, Date.now()) > 0;

/**
 * Checks whether the date is in the future.
 * .
 * @param {Date} date
 * @return {Boolean} Returns true if the date falls after today, otherwise false.
 */
export const isInFuture = (date) =>
  !isToday(date) && differenceInMilliseconds(Date.now(), date) > 0;

/**
 * Checks whether dateA falls before dateB.
 *
 * @param {Date} dateA
 * @param {Date} dateB
 * @return {Boolean} Returns true if dateA falls before dateB, otherwise false
 */
export const fallsBefore = (dateA, dateB) => differenceInMilliseconds(dateA, dateB) > 0;

/**
 * Checks whether date falls in the `start -> end` time period.
 *
 * @param {Date} date
 * @param {Date} start
 * @param {Date} end
 * @return {Boolean} Returns true if date falls in the time period, otherwise false
 */
export const isInTimePeriod = (date, start, end) =>
  differenceInMilliseconds(start, date) >= 0 && differenceInMilliseconds(date, end) >= 0;

/**
 * Removes the time component of the date.
 *
 * @param {Date} date
 * @return {Date} Returns a clone of the date with the time set to midnight
 */
export const removeTime = (date) => {
  const clone = cloneDate(date);
  clone.setHours(0, 0, 0, 0);
  return clone;
};

/**
 * Returns the start of the provided day
 *
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC time.
 * If `true`, the time returned will be midnight UTC. If `false` (the default)
 * the time returned will be midnight in the user's local time.
 *
 * @returns {Date} A new `Date` object that represents the start of the day
 * of the provided date
 */
export const getStartOfDay = (date, { utc = false } = {}) => {
  const clone = cloneDate(date);

  const cloneValue = utc ? clone.setUTCHours(0, 0, 0, 0) : clone.setHours(0, 0, 0, 0);

  return new Date(cloneValue);
};

/**
 * Returns the start of the current week against the provide date
 *
 * @param {Date} date The current date instance to calculate against
 * @param {Object} [options={}] Additional options for this calculation
 * @param {boolean} [options.utc=false] Performs the calculation using UTC time.
 * If `true`, the time returned will be midnight UTC. If `false` (the default)
 * the time returned will be midnight in the user's local time.
 *
 * @returns {Date} A new `Date` object that represents the start of the current week
 * of the provided date
 */
export const getStartOfWeek = (date, { utc = false } = {}) => {
  const cloneValue = utc
    ? new Date(date.setUTCHours(0, 0, 0, 0))
    : new Date(date.setHours(0, 0, 0, 0));

  const diff = cloneValue.getDate() - cloneValue.getDay() + (cloneValue.getDay() === 0 ? -6 : 1);

  return new Date(date.setDate(diff));
};

/**
 * Calculates the time remaining from today in words in the format
 * `n days/weeks/months/years remaining`.
 *
 * @param {Date} date A date in future
 * @return {String} The time remaining in the format `n days/weeks/months/years remaining`
 */
export const getTimeRemainingInWords = (date) => {
  const today = removeTime(new Date());
  const dateInFuture = removeTime(date);

  const oneWeekFromNow = nWeeksAfter(today, 1);
  const oneMonthFromNow = nMonthsAfter(today, 1);
  const oneYearFromNow = nYearsAfter(today, 1);

  if (fallsBefore(dateInFuture, oneWeekFromNow)) {
    const days = getDayDifference(today, dateInFuture);
    return n__('1 day remaining', '%d days remaining', days);
  }

  if (fallsBefore(dateInFuture, oneMonthFromNow)) {
    const weeks = Math.floor(getDayDifference(today, dateInFuture) / 7);
    return n__('1 week remaining', '%d weeks remaining', weeks);
  }

  if (fallsBefore(dateInFuture, oneYearFromNow)) {
    const months = differenceInMonths(today, dateInFuture);
    return n__('1 month remaining', '%d months remaining', months);
  }

  const years = dateInFuture.getFullYear() - today.getFullYear();
  return n__('1 year remaining', '%d years remaining', years);
};

/**
 * Returns the current date according to UTC time at midnight
 * @return {Date} The current date in UTC
 */
export const getCurrentUtcDate = () => {
  const now = new Date();

  return new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
};

/**
 * Returns an array of months between startDate and endDate.
 *
 * @returns {Array<Object>} An array of objects representing months, each containing:
 *   - month {number} - 0-based index (0-11)
 *   - year {number} - The year
 *
 * @example
 * getMonthsBetweenDates(new Date('2024-01-01'), new Date('2024-03-05'))
 *    returns [
      {
          "month": 0,
          "year": 2024,
      },
      {
          "month": 1,
          "year": 2024,
      },
      {
          "month": 2,
          "year": 2024,
      }
  ]
 */

export function getMonthsBetweenDates(startDate, endDate) {
  if (startDate > endDate) {
    return [];
  }

  const startMonth = startDate.getMonth();
  const startYear = startDate.getFullYear();
  const endMonth = endDate.getMonth();
  const endYear = endDate.getFullYear();

  const count = (endYear - startYear) * 12 + (1 + endMonth - startMonth);

  return Array(count)
    .fill(1)
    .map((_, idx) => {
      const month = (idx + startMonth) % 12;
      const yearOffset = Math.floor((idx + startMonth) / 12);

      return {
        month,
        year: startYear + yearOffset,
      };
    });
}

export function convertNanoToMs(nano) {
  return nano / 1e6;
}

export function convertMsToNano(ms) {
  return ms * 1e6;
}

export const isValidDateString = (dateString) => {
  if (typeof dateString !== 'string' || !dateString.trim()) {
    return false;
  }

  let isoFormatted;
  try {
    isoFormatted = dateformat(dateString, 'isoUtcDateTime');
  } catch (e) {
    if (e instanceof TypeError) {
      // not a valid date string
      return false;
    }
    throw e;
  }
  return !Number.isNaN(Date.parse(isoFormatted));
};

/**
 * Converts the given number of days to seconds.
 *
 * @param {number} days Number of days to convert
 *
 * @returns {number} The equivalent number of seconds
 */
export const daysToSeconds = (days) => SECONDS_IN_DAY * days;
