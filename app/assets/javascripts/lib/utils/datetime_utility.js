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
        var $el;
        $el = $(this);
        return $el.attr('title', gl.utils.formatDate($el.attr('datetime')));
      });
      if (setTimeago) {
        $timeagoEls.timeago();
        $timeagoEls.tooltip('destroy');
        return $timeagoEls.tooltip({
          template: '<div class="tooltip local-timeago" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
        });
      }
    };

    w.gl.utils.shortTimeAgo = function($els) {
      clearInterval(window.refreshIntervalId);

      if (!$els.length) {
        return;
      }

      var tmpLocale = $.timeago.settings.strings;
      var shortLocale = {
        prefixAgo: null,
        prefixFromNow: null,
        suffixAgo: 'ago',
        suffixFromNow: 'from now',
        seconds: '1 min',
        minute: '1 min',
        minutes: '%d mins',
        hour: '1 hr',
        hours: '%d hrs',
        day: '1 day',
        days: '%d days',
        month: '1 month',
        months: '%d months',
        year: '1 year',
        years: '%d years',
        wordSeparator: ' ',
        numbers: []
      };

      function updateShortTimeago($els) {
        // Set short locale for timeago
        $.timeago.settings.strings = shortLocale;

        $els.each(function() {
          var $el = $(this);
          var elementDatetime = $.trim($el.data('originalDate') || $el.text());

          // Set short date
          $el.text($.timeago(new Date(elementDatetime)));

          // Set tooltip
          if ($el.data('bs.tooltip')) {
            $el.tooltip('destroy');
          } else {
            $el.data('originalDate', elementDatetime);
          }

          $el.attr('title', gl.utils.formatDate(elementDatetime)); // The tooltip should have the time based on user's timezone
          $el.tooltip();
        });

        // Restore default locale for timeago
        $.timeago.settings.strings = tmpLocale;
      }

      updateShortTimeago($els);

      window.refreshIntervalId = setInterval(function () {
        updateShortTimeago($els);
      }, 60000);
    };

    w.gl.utils.getDayDifference = function(a, b) {
      var millisecondsPerDay = 1000 * 60 * 60 * 24;
      var date1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
      var date2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());

      return Math.floor((date2 - date1) / millisecondsPerDay);
    }

  })(window);

}).call(this);
