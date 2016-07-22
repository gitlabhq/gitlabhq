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
  return w.gl.utils.localTimeAgo = function($timeagoEls, setTimeago) {
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
})(window);
