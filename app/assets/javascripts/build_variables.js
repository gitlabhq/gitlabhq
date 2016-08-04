$(function(){
  $('.reveal-variables').off('click').on('click',function(){
    $('.js-build-variable').toggle();
    $('.js-build-value').toggle().niceScroll();
    $('.reveal-variables').show();
  });
});
