import $ from 'jquery';
import Cookies from 'js-cookie';
import _ from 'underscore';
import bp from './breakpoints';
import { parseBoolean } from '~/lib/utils/common_utils';

export default class ContextualSidebar {
  constructor() {
    this.initDomElements();
    this.render();
  }

  initDomElements() {
    this.$page = $('.layout-page');
    this.$sidebar = $('.nav-sidebar');

    if (!this.$sidebar.length) return;

    this.$innerScroll = $('.nav-sidebar-inner-scroll', this.$sidebar);
    this.$overlay = $('.mobile-overlay');
    this.$openSidebar = $('.toggle-mobile-nav');
    this.$closeSidebar = $('.close-nav-button');
    this.$sidebarToggle = $('.js-toggle-sidebar');
  }

  bindEvents() {
    if (!this.$sidebar.length) return;

    document.addEventListener('click', e => {
      if (
        !e.target.closest('.nav-sidebar') &&
        (bp.getBreakpointSize() === 'sm' || bp.getBreakpointSize() === 'md')
      ) {
        this.toggleCollapsedSidebar(true, true);
      }
    });
    this.$openSidebar.on('click', () => this.toggleSidebarNav(true));
    this.$closeSidebar.on('click', () => this.toggleSidebarNav(false));
    this.$overlay.on('click', () => this.toggleSidebarNav(false));
    this.$sidebarToggle.on('click', () => {
      const value = !this.$sidebar.hasClass('sidebar-collapsed-desktop');
      this.toggleCollapsedSidebar(value, true);
    });

    $(window).on('resize', () => _.debounce(this.render(), 100));
  }

  static setCollapsedCookie(value) {
    if (bp.getBreakpointSize() !== 'lg') {
      return;
    }
    Cookies.set('sidebar_collapsed', value, { expires: 365 * 10 });
  }

  toggleSidebarNav(show) {
    this.$sidebar.toggleClass('sidebar-expanded-mobile', show);
    this.$overlay.toggleClass('mobile-nav-open', show);
    this.$sidebar.removeClass('sidebar-collapsed-desktop');
  }

  toggleCollapsedSidebar(collapsed, saveCookie) {
    const breakpoint = bp.getBreakpointSize();

    if (this.$sidebar.length) {
      this.$sidebar.toggleClass('sidebar-collapsed-desktop', collapsed);
      this.$page.toggleClass('page-with-icon-sidebar', breakpoint === 'sm' ? true : collapsed);
    }

    if (saveCookie) {
      ContextualSidebar.setCollapsedCookie(collapsed);
    }

    requestIdleCallback(this.toggleSidebarOverflow);
  }

  toggleSidebarOverflow() {
    if (this.$innerScroll.prop('scrollHeight') > this.$innerScroll.prop('offsetHeight')) {
      this.$innerScroll.css('overflow-y', 'scroll');
    } else {
      this.$innerScroll.css('overflow-y', '');
    }
  }

  render() {
    if (!this.$sidebar.length) return;

    const breakpoint = bp.getBreakpointSize();

    if (breakpoint === 'sm' || breakpoint === 'md') {
      this.toggleCollapsedSidebar(true, false);
    } else if (breakpoint === 'lg') {
      const collapse = parseBoolean(Cookies.get('sidebar_collapsed'));
      this.toggleCollapsedSidebar(collapse, false);
    }
  }
}
