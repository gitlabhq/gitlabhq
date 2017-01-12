/* eslint-disable func-names, prefer-arrow-callback, space-before-function-paren */

$(function() {
  $('.reveal-variables').off('click').on('click', function() {
    $('.js-build').toggle().niceScroll();
    $(this).hide();
  });
});
