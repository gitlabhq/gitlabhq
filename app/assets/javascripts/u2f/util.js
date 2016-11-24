/* eslint-disable func-names, space-before-function-paren, wrap-iife, padded-blocks */
(function() {
  this.U2FUtil = (function() {
    function U2FUtil() {}

    U2FUtil.isU2FSupported = function() {
      return window.u2f;
    };

    return U2FUtil;

  })();

}).call(this);
