/* eslint-disable arrow-parens, class-methods-use-this, no-param-reassign */
/* global Cookies */

(() => {
  class Sidebar {

    setSidebarHeight() {
      const $navHeight = $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight();
      const diff = $navHeight - $('body').scrollTop();
      if (diff > 0) {
        $('.js-right-sidebar').outerHeight($(window).height() - diff);
      } else {
        $('.js-right-sidebar').outerHeight('100%');
      }
    }
  }

  window.gl = window.gl || {};
  gl.Sidebar = Sidebar;
})();
