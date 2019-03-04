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
      if (!ContextualSidebar.isDesktopBreakpoint()) {
        this.toggleSidebarNav(!this.$sidebar.hasClass('sidebar-expanded-mobile'));
      } else {
        const value = !this.$sidebar.hasClass('sidebar-collapsed-desktop');
        this.toggleCollapsedSidebar(value, true);
      }
    });

    $(window).on('resize', () => _.debounce(this.render(), 100));
  }

  // NOTE: at 1200px sidebar should be in 'desktop' mode
  // https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/24555#note_134136110
  // But, current behaviour starts desktop mode at 1201px

  // TODO: use the breakpoints from breakpoints.js once they have been updated for bootstrap 4
  // See related issue and discussion: https://gitlab.com/gitlab-org/gitlab-ce/issues/56745
  static isDesktopBreakpoint = () => bp.windowWidth() > 1200;
  static setCollapsedCookie(value) {
    if (bp.getBreakpointSize() !== 'lg') {
      return;
    }
    Cookies.set('sidebar_collapsed', value, { expires: 365 * 10 });
  }

  toggleSidebarNav(show) {
    const breakpoint = bp.getBreakpointSize();
    const dbp = ContextualSidebar.isDesktopBreakpoint();

    this.$sidebar.toggleClass('sidebar-expanded-mobile', !dbp ? show : false);
    this.$overlay.toggleClass('mobile-nav-open', breakpoint === 'xs' ? show : false);
    this.$sidebar.removeClass('sidebar-collapsed-desktop');
  }

  toggleCollapsedSidebar(collapsed, saveCookie) {
    const breakpoint = bp.getBreakpointSize();
    const dbp = ContextualSidebar.isDesktopBreakpoint(breakpoint);

    if (this.$sidebar.length) {
      this.$sidebar.toggleClass('sidebar-collapsed-desktop', collapsed);
      this.$sidebar.toggleClass('sidebar-expanded-mobile', !dbp ? !collapsed : false);
      this.$page.toggleClass('page-with-icon-sidebar', breakpoint === 'sm' ? true : collapsed);
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
    if (!ContextualSidebar.isDesktopBreakpoint()) {
      this.toggleSidebarNav(false);
    } else if (breakpoint === 'lg') {
      const collapse = parseBoolean(Cookies.get('sidebar_collapsed'));
      this.toggleCollapsedSidebar(collapse, false);
    }
  }
}
