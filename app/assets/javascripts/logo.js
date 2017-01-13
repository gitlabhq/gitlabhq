/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback */

(function() {
  $(window).on('beforeunload', function() {
    $('.tanuki-logo').addClass('animate');
  });
}).call(this);
