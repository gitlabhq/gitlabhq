(function() {
  var collapsed, expanded, toggleSidebar;

  collapsed = 'page-sidebar-collapsed';

  expanded = 'page-sidebar-expanded';

  toggleSidebar = function() {
    $('.page-with-sidebar').toggleClass(collapsed + " " + expanded);
    $('.navbar-fixed-top').toggleClass("header-collapsed header-expanded");
    if ($.cookie('pin_nav') === 'true') {
      $('.navbar-fixed-top').toggleClass('header-pinned-nav');
      $('.page-with-sidebar').toggleClass('page-sidebar-pinned');
    }
    return setTimeout((function() {
      var niceScrollBars;
      niceScrollBars = $('.nav-sidebar').niceScroll();
      return niceScrollBars.updateScrollBar();
    }), 300);
  };

  $(document).off('click', 'body').on('click', 'body', function(e) {
    var $nav, $target, $toggle, pageExpanded;
    if ($.cookie('pin_nav') !== 'true') {
      $target = $(e.target);
      $nav = $target.closest('.sidebar-wrapper');
      pageExpanded = $('.page-with-sidebar').hasClass('page-sidebar-expanded');
      $toggle = $target.closest('.toggle-nav-collapse, .side-nav-toggle');
      if ($nav.length === 0 && pageExpanded && $toggle.length === 0) {
        $('.page-with-sidebar').toggleClass('page-sidebar-collapsed page-sidebar-expanded');
        return $('.navbar-fixed-top').toggleClass('header-collapsed header-expanded');
      }
    }
  });

  $(document).on("click", '.toggle-nav-collapse, .side-nav-toggle', function(e) {
    e.preventDefault();
    return toggleSidebar();
  });

}).call(this);
