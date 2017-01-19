/* eslint-disable func-names, prefer-arrow-callback, space-before-blocks, space-before-function-paren, comma-spacing, max-len */

$(function(){
  $('.reveal-variables').off('click').on('click',function(){
    $('.js-build').toggle().niceScroll();
    $(this).hide();
  });
});
