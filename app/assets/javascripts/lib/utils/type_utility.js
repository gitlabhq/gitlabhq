(function() {
  (function(w) {
    var base;
    if (w.gl == null) {
      w.gl = {};
    }
    if ((base = w.gl).utils == null) {
      base.utils = {};
    }
    return w.gl.utils.isObject = function(obj) {
      return (obj != null) && (obj.constructor === Object);
    };
  })(window);

}).call(this);
