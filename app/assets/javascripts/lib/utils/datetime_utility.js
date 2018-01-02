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

export function dateInWords(date, abbreviated = false) {
  if (!date) return date;

  const month = date.getMonth();
  const year = date.getFullYear();

  const monthNames = [s__('January'), s__('February'), s__('March'), s__('April'), s__('May'), s__('June'), s__('July'), s__('August'), s__('September'), s__('October'), s__('November'), s__('December')];
  const monthNamesAbbr = [s__('Jan'), s__('Feb'), s__('Mar'), s__('Apr'), s__('May'), s__('Jun'), s__('Jul'), s__('Aug'), s__('Sep'), s__('Oct'), s__('Nov'), s__('Dec')];

  const monthName = abbreviated ? monthNamesAbbr[month] : monthNames[month];

  return `${monthName} ${date.getDate()}, ${year}`;
}

window.gl = window.gl || {};
window.gl.utils = {
  ...(window.gl.utils || {}),
  getTimeago,
  localTimeAgo,
};
