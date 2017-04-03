/* eslint-disable func-names, space-before-function-paren, wrap-iife */
(function() {
  this.U2FUtil = (function() {
    function U2FUtil() {}

    U2FUtil.isU2FSupported = function() {
      return window.u2f;
    };

    return U2FUtil;
  })();
}).call(window);
