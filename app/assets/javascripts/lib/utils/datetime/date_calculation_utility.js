import { isNumber } from 'lodash';
import { __, n__ } from '../../../locale';
import { getDayName, parseSeconds } from './date_format_utility';

const DAYS_IN_WEEK = 7;
export const SECONDS_IN_DAY = 86400;
export const MILLISECONDS_IN_DAY = 24 * 60 * 60 * 1000;

/**
 * This method allows you to create new Date instance from existing
 * date instance without keeping the reference.
 *
 * @param {Date} date
 */
export const newDate = (date) => (date instanceof Date ? new Date(date.getTime()) : new Date());

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

export const millisecondsPerDay = 1000 * 60 * 60 * 24;

export const getDayDifference = (a, b) => {
  const date1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
  const date2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());

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

/**
 * Checks if a given date-instance was created with a valid date
 *
 * @param  {Date} date
 * @returns boolean
 */
export const isValidDate = (date) => date instanceof Date && !Number.isNaN(date.getTime());

/*
 * Appending T00:00:00 makes JS assume local time and prevents it from shifting the date
 * to match the user's time zone. We want to display the date in server time for now, to
 * be consistent with the "edit issue -> due date" UI.
 */

export const newDateAsLocaleTime = (date) => {
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
 * Converts a numeric utc offset in seconds to +/- hours
 * ie -32400 => -9 hours
 * ie -12600 => -3.5 hours
 *
 * @param {Number} offset UTC offset in seconds as a integer
 *
 * @return {String} the + or - offset in hours
 */
export const secondsToHours = (offset) => {
  const parsed = parseInt(offset, 10);
  if (Number.isNaN(parsed) || parsed === 0) {
    return `0`;
  }
  const num = offset / 3600;
  return parseInt(num, 10) !== num ? num.toFixed(1) : num;
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
  const clone = newDate(date);

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
  const clone = newDate(date);

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
 *
 * @param {Date} date the initial date
 * @param {Number} numberOfYears number of years after
 * @return {Date} A `Date` object `n` years after the provided `Date`
 */
export const nYearsAfter = (date, numberOfYears) => {
  const clone = newDate(date);
  clone.setFullYear(clone.getFullYear() + numberOfYears);
  return clone;
};

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
export const dateAtFirstDayOfMonth = (date) => new Date(newDate(date).setDate(1));

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
 * A utility function which checks if two date ranges overlap.
 *
 * @param {Object} givenPeriodLeft - the first period to compare.
 * @param {Object} givenPeriodRight - the second period to compare.
 * @returns {Object} { overlap: number of days the overlap is present, overlapStartDate: the start date of the overlap in time format, overlapEndDate: the end date of the overlap in time format }
 * @throws {Error} Uncaught Error: Invalid period
 *
 * @example
 * getOverlappingDaysInPeriods(
 *   { start: new Date(2021, 0, 11), end: new Date(2021, 0, 13) },
 *   { start: new Date(2021, 0, 11), end: new Date(2021, 0, 14) }
 * ) => { daysOverlap: 2, overlapStartDate: 1610323200000, overlapEndDate: 1610496000000 }
 *
 */
export const getOverlappingDaysInPeriods = (givenPeriodLeft = {}, givenPeriodRight = {}) => {
  const leftStartTime = new Date(givenPeriodLeft.start).getTime();
  const leftEndTime = new Date(givenPeriodLeft.end).getTime();
  const rightStartTime = new Date(givenPeriodRight.start).getTime();
  const rightEndTime = new Date(givenPeriodRight.end).getTime();

  if (!(leftStartTime <= leftEndTime && rightStartTime <= rightEndTime)) {
    throw new Error(__('Invalid period'));
  }

  const isOverlapping = leftStartTime < rightEndTime && rightStartTime < leftEndTime;

  if (!isOverlapping) {
    return { daysOverlap: 0 };
  }

  const overlapStartDate = Math.max(leftStartTime, rightStartTime);
  const overlapEndDate = rightEndTime > leftEndTime ? leftEndTime : rightEndTime;
  const differenceInMs = overlapEndDate - overlapStartDate;

  return {
    daysOverlap: Math.ceil(differenceInMs / MILLISECONDS_IN_DAY),
    overlapStartDate,
    overlapEndDate,
  };
};

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
  if (!isNumber(seconds) || seconds < 0) {
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

/**
 * A utility function which helps creating a date object
 * for a specific date. Accepts the year, month and day
 * returning a date object for the given params.
 *
 * @param {Int} year the full year as a number i.e. 2020
 * @param {Int} month the month index i.e. January => 0
 * @param {Int} day the day as a number i.e. 23
 *
 * @return {Date} the date object from the params
 */
export const dateFromParams = (year, month, day) => {
  return new Date(year, month, day);
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
 * Removes the time component of the date.
 *
 * @param {Date} date
 * @return {Date} Returns a clone of the date with the time set to midnight
 */
export const removeTime = (date) => {
  const clone = newDate(date);
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
  const clone = newDate(date);

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
