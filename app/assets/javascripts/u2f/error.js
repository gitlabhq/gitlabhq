/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-console, quotes, prefer-template, max-len */
/* global u2f */

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

  this.U2FError = (function() {
    function U2FError(errorCode, u2fFlowType) {
      this.errorCode = errorCode;
      this.message = bind(this.message, this);
      this.httpsDisabled = window.location.protocol !== 'https:';
      this.u2fFlowType = u2fFlowType;
    }

    U2FError.prototype.message = function() {
      if (this.errorCode === u2f.ErrorCodes.BAD_REQUEST && this.httpsDisabled) {
        return 'U2F only works with HTTPS-enabled websites. Contact your administrator for more details.';
      } else if (this.errorCode === u2f.ErrorCodes.DEVICE_INELIGIBLE) {
        if (this.u2fFlowType === 'authenticate') return 'This device has not been registered with us.';
        if (this.u2fFlowType === 'register') return 'This device has already been registered with us.';
      }
      return "There was a problem communicating with your device.";
    };

    return U2FError;
  })();
}).call(window);
