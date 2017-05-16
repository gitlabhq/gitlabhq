/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, comma-dangle, no-unused-expressions, prefer-template, max-len */
/* global timeago */
/* global dateFormat */

import {
  lang,
  s__,
} from '../../locale';

window.timeago = require('timeago.js');
window.dateFormat = require('vendor/date.format');

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
        el.setAttribute('title', gl.utils.formatDate(el.getAttribute('datetime')));

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
            [s__('Timeago|less than a minute ago'), s__('Timeago|a while')],
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
            [s__('Timeago|less than a minute ago'), s__('Timeago|a while')],
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

    w.gl.utils.cachedTimeagoElements = [];
    w.gl.utils.renderTimeago = function($els) {
      if (!$els && !w.gl.utils.cachedTimeagoElements.length) {
        w.gl.utils.cachedTimeagoElements = [].slice.call(document.querySelectorAll('.js-timeago-render'));
      } else if ($els) {
        w.gl.utils.cachedTimeagoElements = w.gl.utils.cachedTimeagoElements.concat($els.toArray());
      }

      w.gl.utils.cachedTimeagoElements.forEach(gl.utils.updateTimeagoText);
    };

    w.gl.utils.updateTimeagoText = function(el) {
      const timeago = gl.utils.getTimeago();
      const formattedDate = timeago.format(el.getAttribute('datetime'), lang);

      if (el.textContent !== formattedDate) {
        el.textContent = formattedDate;
      }
    };

    w.gl.utils.initTimeagoTimeout = function() {
      gl.utils.renderTimeago();

      gl.utils.timeagoTimeout = setTimeout(gl.utils.initTimeagoTimeout, 1000);
    };

    w.gl.utils.getDayDifference = function(a, b) {
      var millisecondsPerDay = 1000 * 60 * 60 * 24;
      var date1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
      var date2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());

      return Math.floor((date2 - date1) / millisecondsPerDay);
    };
  })(window);
}).call(window);
