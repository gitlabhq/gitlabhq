/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, padded-blocks */
/* global Turbolinks */

(function() {
  Turbolinks.enableProgressBar();

  $(document).on('page:fetch', function() {
    $('.tanuki-logo').addClass('animate');
  });

  $(document).on('page:change', function() {
    $('.tanuki-logo').removeClass('animate');
  });

}).call(this);
