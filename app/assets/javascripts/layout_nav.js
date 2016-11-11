/* eslint-disable */
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
    var $scrollingTabs = $('.scrolling-tabs');

    hideEndFade($scrollingTabs);
    $(window).off('resize.nav').on('resize.nav', function() {
      return hideEndFade($scrollingTabs);
    });
    $scrollingTabs.off('scroll').on('scroll', function(event) {
      var $this, currentPosition, maxPosition;
      $this = $(this);
      currentPosition = $this.scrollLeft();
      maxPosition = $this.prop('scrollWidth') - $this.outerWidth();
      $this.siblings('.fade-left').toggleClass('scrolling', currentPosition > 0);
      return $this.siblings('.fade-right').toggleClass('scrolling', currentPosition < maxPosition - 1);
    });

    $scrollingTabs.each(function () {
      var $this = $(this),
          scrollingTabWidth = $this.width(),
          $active = $this.find('.active'),
          activeWidth = $active.width();

      if ($active.length) {
        var offset = $active.offset().left + activeWidth;

        if (offset > scrollingTabWidth - 30) {
          var scrollLeft = scrollingTabWidth / 2;
          scrollLeft = (offset - scrollLeft) - (activeWidth / 2);
          $this.scrollLeft(scrollLeft);
        }
      }
    });
  });

}).call(this);
