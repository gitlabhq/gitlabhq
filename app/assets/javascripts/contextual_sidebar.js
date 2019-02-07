import $ from 'jquery';
import Cookies from 'js-cookie';
import _ from 'underscore';
import bp from './breakpoints';
import { parseBoolean } from '~/lib/utils/common_utils';

const DESKTOP_BREAKPOINTS = ['xl', 'lg'];
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
      const breakpoint = bp.getBreakpointSize();

      if (!ContextualSidebar.isDesktopBreakpoint(breakpoint)) {
        this.toggleSidebarNav(!this.$sidebar.hasClass('sidebar-expanded-mobile'));
      } else if (breakpoint === 'lg') {
        const value = !this.$sidebar.hasClass('sidebar-collapsed-desktop');
        this.toggleCollapsedSidebar(value, true);
      }
    });

    $(window).on('resize', () => _.debounce(this.render(), 100));
  }

  // TODO: use the breakpoints from breakpoints.js once they have been updated for bootstrap 4
  // See related issue and discussion: https://gitlab.com/gitlab-org/gitlab-ce/issues/56745
  static isDesktopBreakpoint = (_bp = '') => DESKTOP_BREAKPOINTS.indexOf(_bp) > -1;
  static setCollapsedCookie(value) {
    if (bp.getBreakpointSize() !== 'lg') {
      return;
    }
    Cookies.set('sidebar_collapsed', value, { expires: 365 * 10 });
  }

  toggleSidebarNav(show) {
    const breakpoint = bp.getBreakpointSize();
    const dbp = ContextualSidebar.isDesktopBreakpoint(breakpoint);

    this.$sidebar.toggleClass('sidebar-expanded-mobile', !dbp ? show : false);
    this.$overlay.toggleClass('mobile-nav-open', breakpoint === 'xs' ? show : false);
    this.$sidebar.removeClass('sidebar-collapsed-desktop');
    this.$page.toggleClass('page-with-contextual-sidebar', true);
  }

  toggleCollapsedSidebar(collapsed, saveCookie) {
    const breakpoint = bp.getBreakpointSize();
    const dbp = ContextualSidebar.isDesktopBreakpoint(breakpoint);

    if (this.$sidebar.length) {
      this.$sidebar.toggleClass('sidebar-collapsed-desktop', collapsed);
      this.$sidebar.toggleClass('sidebar-expanded-mobile', !dbp ? !collapsed : false);
      this.$page.toggleClass('page-with-icon-sidebar', breakpoint === 'sm' ? true : collapsed);
      this.$page.toggleClass('page-with-contextual-sidebar', true);
    }

    if (saveCookie) {
      ContextualSidebar.setCollapsedCookie(collapsed);
    }

    requestIdleCallback(() => this.toggleSidebarOverflow());
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
    if (!ContextualSidebar.isDesktopBreakpoint(breakpoint)) {
      this.toggleSidebarNav(false);
    } else if (breakpoint === 'lg') {
      const collapse = parseBoolean(Cookies.get('sidebar_collapsed'));
      this.toggleCollapsedSidebar(collapse, false);
    }
  }
}
