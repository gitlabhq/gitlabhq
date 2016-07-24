(function() {
  var hideEndFade;

  hideEndFade = function($scrollingTabs) {
    return $scrollingTabs.each(function() {
      var $this;
      $this = $(this);
      return $this.siblings('.fade-right').toggleClass('scrolling', $this.width() < $this.prop('scrollWidth'));
    });
  };

  $(function() {
    hideEndFade($('.scrolling-tabs'));
    $(window).off('resize.nav').on('resize.nav', function() {
      return hideEndFade($('.scrolling-tabs'));
    });
    return $('.scrolling-tabs').on('scroll', function(event) {
      var $this, currentPosition, maxPosition;
      $this = $(this);
      currentPosition = $this.scrollLeft();
      maxPosition = $this.prop('scrollWidth') - $this.outerWidth();
      $this.siblings('.fade-left').toggleClass('scrolling', currentPosition > 0);
      return $this.siblings('.fade-right').toggleClass('scrolling', currentPosition < maxPosition - 1);
    });
  });

}).call(this);
