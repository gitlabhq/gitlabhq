/* eslint-disable func-names, space-before-function-paren, no-var, prefer-arrow-callback, no-unused-vars, one-var, one-var-declaration-per-line, vars-on-top, max-len */
import _ from 'underscore';
import Cookies from 'js-cookie';
import ContextualSidebar from './contextual_sidebar';
import initFlyOutNav from './fly_out_nav';

(function() {
  var hideEndFade;

  hideEndFade = function($scrollingTabs) {
    return $scrollingTabs.each(function() {
      var $this;
      $this = $(this);
      return $this.siblings('.fade-right').toggleClass('scrolling', $this.width() < $this.prop('scrollWidth'));
    });
  };

  $(document).on('init.scrolling-tabs', () => {
    const $scrollingTabs = $('.scrolling-tabs').not('.is-initialized');
    $scrollingTabs.addClass('is-initialized');

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
      var $this = $(this);
      var scrollingTabWidth = $this.width();
      var $active = $this.find('.active');
      var activeWidth = $active.width();

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

  $(() => {
    const contextualSidebar = new ContextualSidebar();
    contextualSidebar.bindEvents();

    initFlyOutNav();
  });
}).call(window);
