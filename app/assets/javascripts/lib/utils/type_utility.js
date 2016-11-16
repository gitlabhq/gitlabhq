/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, no-param-reassign, no-cond-assign, no-return-assign, padded-blocks, max-len */
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
