/* eslint-disable */
(function() {
  (function(w) {
    var base;
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

    w.gl.utils.localTimeAgo = function($timeagoEls, setTimeago) {
      if (setTimeago == null) {
        setTimeago = true;
      }

      $timeagoEls.each(function() {
        var $el = $(this);
        $el.attr('title', gl.utils.formatDate($el.attr('datetime')));

        if (setTimeago) {
          // Recreate with custom template
          $el.tooltip({
            template: '<div class="tooltip local-timeago" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
          });
        }
        gl.utils.renderTimeago($el);
      });
    };

    w.gl.utils.getTimeago = function() {
      var locale = function(number, index) {
        return [
          ['less than a minute ago', 'a while'],
          ['less than a minute ago', 'in %s seconds'],
          ['about a minute ago', 'in 1 minute'],
          ['%s minutes ago', 'in %s minutes'],
          ['about an hour ago', 'in 1 hour'],
          ['about %s hours ago', 'in %s hours'],
          ['a day ago', 'in 1 day'],
          ['%s days ago', 'in %s days'],
          ['a week ago', 'in 1 week'],
          ['%s weeks ago', 'in %s weeks'],
          ['a month ago', 'in 1 month'],
          ['%s months ago', 'in %s months'],
          ['a year ago', 'in 1 year'],
          ['%s years ago', 'in %s years']
        ][index];
      };

      timeago.register('gl_en', locale);
      return timeago();
    };

    w.gl.utils.timeFor = function(time, suffix, expiredLabel) {
      var timefor;
      if (!time) {
        return '';
      }
      suffix || (suffix = 'remaining');
      expiredLabel || (expiredLabel = 'Past due');
      timefor = gl.utils.getTimeago().format(time).replace('in', '');
      if (timefor.indexOf('ago') > -1) {
        timefor = expiredLabel;
      } else {
        timefor = timefor.trim() + ' ' + suffix;
      }
      return timefor;
    };

    w.gl.utils.renderTimeago = function($element) {
      var timeagoInstance = gl.utils.getTimeago();
      timeagoInstance.render($element, 'gl_en');
    };

    w.gl.utils.getDayDifference = function(a, b) {
      var millisecondsPerDay = 1000 * 60 * 60 * 24;
      var date1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
      var date2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());

      return Math.floor((date2 - date1) / millisecondsPerDay);
    };

  })(window);

}).call(this);
