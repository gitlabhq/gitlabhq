/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, comma-dangle, no-unused-expressions, prefer-template, max-len */

import timeago from 'timeago.js';
import dateFormat from 'vendor/date.format';
import { pluralize } from './text_utility';

import {
  lang,
  s__,
} from '../../locale';

window.timeago = timeago;
window.dateFormat = dateFormat;

(function() {
  (function(w) {
    var base;
    var timeagoInstance;

    if (w.gl == null) {
      w.gl = {};
    }
    if ((base = w.gl).utils == null) {
      base.utils = {};
    }
    w.gl.utils.days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    w.gl.utils.formatDate = function(datetime) {
      return dateFormat(datetime, 'mmm d, yyyy h:MMtt Z');
    };

    w.gl.utils.getDayName = function(date) {
      return this.days[date.getDay()];
    };

    w.gl.utils.localTimeAgo = function($timeagoEls, setTimeago = true) {
      $timeagoEls.each((i, el) => {
        el.setAttribute('title', el.getAttribute('title'));

        if (setTimeago) {
          // Recreate with custom template
          $(el).tooltip({
            template: '<div class="tooltip local-timeago" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
          });
        }

        el.classList.add('js-timeago-render');
      });

      gl.utils.renderTimeago($timeagoEls);
    };

    w.gl.utils.getTimeago = function() {
      var locale;

      if (!timeagoInstance) {
        const localeRemaining = function(number, index) {
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
            [s__('Timeago|%s years ago'), s__('Timeago|%s years remaining')]
          ][index];
        };
        locale = function(number, index) {
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
            [s__('Timeago|%s years ago'), s__('Timeago|in %s years')]
          ][index];
        };

        timeago.register(lang, locale);
        timeago.register(`${lang}-remaining`, localeRemaining);
        timeagoInstance = timeago();
      }

      return timeagoInstance;
    };

    w.gl.utils.timeFor = function(time, suffix, expiredLabel) {
      var timefor;
      if (!time) {
        return '';
      }
      if (new Date(time) < new Date()) {
        expiredLabel || (expiredLabel = s__('Timeago|Past due'));
        timefor = expiredLabel;
      } else {
        timefor = gl.utils.getTimeago().format(time, `${lang}-remaining`).trim();
      }
      return timefor;
    };

    w.gl.utils.renderTimeago = function($els) {
      const timeagoEls = $els || document.querySelectorAll('.js-timeago-render');

      // timeago.js sets timeouts internally for each timeago value to be updated in real time
      gl.utils.getTimeago().render(timeagoEls, lang);
    };

    w.gl.utils.getDayDifference = function(a, b) {
      var millisecondsPerDay = 1000 * 60 * 60 * 24;
      var date1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
      var date2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());

      return Math.floor((date2 - date1) / millisecondsPerDay);
    };
  })(window);
}).call(window);

/**
 * Port of ruby helper time_interval_in_words.
 *
 * @param  {Number} seconds
 * @return {String}
 */
// eslint-disable-next-line import/prefer-default-export
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
