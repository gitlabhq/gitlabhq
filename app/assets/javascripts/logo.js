/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, padded-blocks, no-var, max-len */
/* global Turbolinks */

(function() {
  var $document = $(document);

  Turbolinks.enableProgressBar();

  $document.off('page:fetch.startAnimation')
    .on('page:fetch.startAnimation', function() {
      $('.tanuki-logo').addClass('animate');
    });

  $document.off('page:change.stopAnimation')
    .on('page:change.stopAnimation', function() {
      $('.tanuki-logo').removeClass('animate');
    });

}).call(this);
