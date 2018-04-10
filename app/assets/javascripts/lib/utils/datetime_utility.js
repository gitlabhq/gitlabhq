import $ from 'jquery';
import timeago from 'timeago.js';
import dateFormat from 'vendor/date.format';
import { pluralize } from './text_utility';
import {
  languageCode,
  s__,
} from '../../locale';

window.timeago = timeago;
window.dateFormat = dateFormat;

/**
 * Returns i18n month names array.
 * If `abbreviated` is provided, returns abbreviated
 * name.
 *
 * @param {Boolean} abbreviated
 */
const getMonthNames = (abbreviated) => {
  if (abbreviated) {
    return [s__('Jan'), s__('Feb'), s__('Mar'), s__('Apr'), s__('May'), s__('Jun'), s__('Jul'), s__('Aug'), s__('Sep'), s__('Oct'), s__('Nov'), s__('Dec')];
  }
  return [s__('January'), s__('February'), s__('March'), s__('April'), s__('May'), s__('June'), s__('July'), s__('August'), s__('September'), s__('October'), s__('November'), s__('December')];
};

/**
 * Given a date object returns the day of the week in English
 * @param {date} date
 * @returns {String}
 */
export const getDayName = date => ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][date.getDay()];

/**
 * @example
 * dateFormat('2017-12-05','mmm d, yyyy h:MMtt Z' ) -> "Dec 5, 2017 12:00am GMT+0000"
 * @param {date} datetime
 * @returns {String}
 */
export const formatDate = datetime => dateFormat(datetime, 'mmm d, yyyy h:MMtt Z');

/**
 * Timeago uses underscores instead of dashes to separate language from country code.
 *
 * see https://github.com/hustcc/timeago.js/tree/v3.0.0/locales
 */
const timeagoLanguageCode = languageCode().replace(/-/g, '_');

let timeagoInstance;

/**
 * Sets a timeago Instance
 */
export function getTimeago() {
  if (!timeagoInstance) {
    const localeRemaining = function getLocaleRemaining(number, index) {
      return [
        [s__('Timeago|less than a minute ago'), s__('Timeago|in a while')],
        [s__('Timeago|less than a minute ago'), s__('Timeago|%s seconds remaining')],
        [s__('Timeago|about a minute ago'), s__('Timeago|1 minute remaining')],
        [s__('Timeago|%s minutes ago'), s__('Timeago|%s minutes remaining')],
        [s__('Timeago|about an hour ago'), s__('Timeago|1 hour remaining')],
        [s__('Timeago|about %s hours ago'), s__('Timeago|%s hours remaining')],
        [s__('Timeago|a day ago'), s__('Timeago|1 day remaining')],
        [s__('Timeago|%s days ago'), s__('Timeago|%s days remaining')],
        [s__('Timeago|a week ago'), s__('Timeago|1 week remaining')],
        [s__('Timeago|%s weeks ago'), s__('Timeago|%s weeks remaining')],
        [s__('Timeago|a month ago'), s__('Timeago|1 month remaining')],
        [s__('Timeago|%s months ago'), s__('Timeago|%s months remaining')],
        [s__('Timeago|a year ago'), s__('Timeago|1 year remaining')],
        [s__('Timeago|%s years ago'), s__('Timeago|%s years remaining')],
      ][index];
    };
    const locale = function getLocale(number, index) {
      return [
        [s__('Timeago|less than a minute ago'), s__('Timeago|in a while')],
        [s__('Timeago|less than a minute ago'), s__('Timeago|in %s seconds')],
        [s__('Timeago|about a minute ago'), s__('Timeago|in 1 minute')],
        [s__('Timeago|%s minutes ago'), s__('Timeago|in %s minutes')],
        [s__('Timeago|about an hour ago'), s__('Timeago|in 1 hour')],
        [s__('Timeago|about %s hours ago'), s__('Timeago|in %s hours')],
        [s__('Timeago|a day ago'), s__('Timeago|in 1 day')],
        [s__('Timeago|%s days ago'), s__('Timeago|in %s days')],
        [s__('Timeago|a week ago'), s__('Timeago|in 1 week')],
        [s__('Timeago|%s weeks ago'), s__('Timeago|in %s weeks')],
        [s__('Timeago|a month ago'), s__('Timeago|in 1 month')],
        [s__('Timeago|%s months ago'), s__('Timeago|in %s months')],
        [s__('Timeago|a year ago'), s__('Timeago|in 1 year')],
        [s__('Timeago|%s years ago'), s__('Timeago|in %s years')],
      ][index];
    };

    timeago.register(timeagoLanguageCode, locale);
    timeago.register(`${timeagoLanguageCode}-remaining`, localeRemaining);
    timeagoInstance = timeago();
  }

  return timeagoInstance;
}

/**
 * For the given element, renders a timeago instance.
 * @param {jQuery} $els
 */
export const renderTimeago = ($els) => {
  const timeagoEls = $els || document.querySelectorAll('.js-timeago-render');

  // timeago.js sets timeouts internally for each timeago value to be updated in real time
  getTimeago().render(timeagoEls, timeagoLanguageCode);
};

/**
 * For the given elements, sets a tooltip with a formatted date.
 * @param {jQuery}
 * @param {Boolean} setTimeago
 */
export const localTimeAgo = ($timeagoEls, setTimeago = true) => {
  $timeagoEls.each((i, el) => {
    if (setTimeago) {
      // Recreate with custom template
      $(el).tooltip({
        template: '<div class="tooltip local-timeago" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>',
      });
    }

    el.classList.add('js-timeago-render');
  });

  renderTimeago($timeagoEls);
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
  return getTimeago().format(time, `${timeagoLanguageCode}-remaining`).trim();
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
export function timeIntervalInWords(intervalInSeconds) {
  const secondsInteger = parseInt(intervalInSeconds, 10);
  const minutes = Math.floor(secondsInteger / 60);
  const seconds = secondsInteger - (minutes * 60);
  let text = '';

  if (minutes >= 1) {
    text = `${minutes} ${pluralize('minute', minutes)} ${seconds} ${pluralize('second', seconds)}`;
  } else {
    text = `${seconds} ${pluralize('second', seconds)}`;
  }
  return text;
}

export function dateInWords(date, abbreviated = false, hideYear = false) {
  if (!date) return date;

  const month = date.getMonth();
  const year = date.getFullYear();

  const monthNames = [s__('January'), s__('February'), s__('March'), s__('April'), s__('May'), s__('June'), s__('July'), s__('August'), s__('September'), s__('October'), s__('November'), s__('December')];
  const monthNamesAbbr = [s__('Jan'), s__('Feb'), s__('Mar'), s__('Apr'), s__('May'), s__('Jun'), s__('Jul'), s__('Aug'), s__('Sep'), s__('Oct'), s__('Nov'), s__('Dec')];

  const monthName = abbreviated ? monthNamesAbbr[month] : monthNames[month];

  if (hideYear) {
    return `${monthName} ${date.getDate()}`;
  }

  return `${monthName} ${date.getDate()}, ${year}`;
}

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
export const totalDaysInMonth = (date) => {
  if (!date) {
    return 0;
  }
  return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
};

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

  const daysToSunday = ['Saturday', 'Friday', 'Thursday', 'Wednesday', 'Tuesday', 'Monday', 'Sunday'];

  const month = date.getMonth();
  const year = date.getFullYear();
  const sundays = [];
  const dateOfMonth = new Date(year, month, 1);

  while (dateOfMonth.getMonth() === month) {
    const dayName = getDayName(dateOfMonth);
    if (dayName === 'Sunday') {
      sundays.push(new Date(dateOfMonth.getTime()));
    }

    const daysUntilNextSunday = daysToSunday.indexOf(dayName) + 1;
    dateOfMonth.setDate(dateOfMonth.getDate() + daysUntilNextSunday);
  }

  return sundays;
};

/**
 * Returns list of Dates representing a timeframe of Months from month of provided date (inclusive)
 * up to provided length
 *
 * For eg;
 *    If current month is January 2018 and `length` provided is `6`
 *    Then this method will return list of Date objects as follows;
 *
 *    [ October 2017, November 2017, December 2017, January 2018, February 2018, March 2018 ]
 *
 *    If current month is March 2018 and `length` provided is `3`
 *    Then this method will return list of Date objects as follows;
 *
 *    [ February 2018, March 2018, April 2018 ]
 *
 * @param {Number} length
 * @param {Date} date
 */
export const getTimeframeWindow = (length, date) => {
  if (!length) {
    return [];
  }

  const currentDate = date instanceof Date ? date : new Date();
  const currentMonthIndex = Math.floor(length / 2);
  const timeframe = [];

  // Move date object backward to the first month of timeframe
  currentDate.setDate(1);
  currentDate.setMonth(currentDate.getMonth() - currentMonthIndex);

  // Iterate and update date for the size of length
  // and push date reference to timeframe list
  for (let i = 0; i < length; i += 1) {
    timeframe.push(new Date(currentDate.getTime()));
    currentDate.setMonth(currentDate.getMonth() + 1);
  }

  // Change date of last timeframe item to last date of the month
  timeframe[length - 1].setDate(totalDaysInMonth(timeframe[length - 1]));

  return timeframe;
};

window.gl = window.gl || {};
window.gl.utils = {
  ...(window.gl.utils || {}),
  getTimeago,
  localTimeAgo,
};
