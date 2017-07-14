/* eslint-disable func-names, space-before-function-paren, wrap-iife */
function U2FUtil() {}

U2FUtil.isU2FSupported = function() {
  return window.u2f;
};

window.U2FUtil = U2FUtil;
