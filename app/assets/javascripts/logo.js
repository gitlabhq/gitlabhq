/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback */

(function() {
  window.addEventListener('beforeunload', function() {
    $('.tanuki-logo').addClass('animate');
  });
}).call(window);
