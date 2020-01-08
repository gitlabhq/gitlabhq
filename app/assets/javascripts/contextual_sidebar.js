import $ from 'jquery';
import Cookies from 'js-cookie';
import _ from 'underscore';
import { GlBreakpointInstance as bp, breakpoints } from '@gitlab/ui/dist/utils';
import { parseBoolean } from '~/lib/utils/common_utils';

export const SIDEBAR_COLLAPSED_CLASS = 'js-sidebar-collapsed';

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
    this.$page.on('transitionstart transitionend', () => {
      $(document).trigger('content.resize');
    });

    $(window).on('resize', () => _.debounce(this.render(), 100));
  }

  // See documentation: https://design.gitlab.com/regions/navigation#contextual-navigation
  // NOTE: at 1200px nav sidebar should not overlap the content
  // https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/24555#note_134136110
  static isDesktopBreakpoint = () => bp.windowWidth() >= breakpoints.xl;
  static setCollapsedCookie(value) {
    if (!ContextualSidebar.isDesktopBreakpoint()) {
      return;
    }
    Cookies.set('sidebar_collapsed', value, { expires: 365 * 10 });
  }

  toggleSidebarNav(show) {
    const breakpoint = bp.getBreakpointSize();
    const dbp = ContextualSidebar.isDesktopBreakpoint();
    const supportedSizes = ['xs', 'sm', 'md'];

    this.$sidebar.toggleClass(SIDEBAR_COLLAPSED_CLASS, !show);
    this.$sidebar.toggleClass('sidebar-expanded-mobile', !dbp ? show : false);
    this.$overlay.toggleClass(
      'mobile-nav-open',
      supportedSizes.includes(breakpoint) ? show : false,
    );
    this.$sidebar.removeClass('sidebar-collapsed-desktop');
  }

  toggleCollapsedSidebar(collapsed, saveCookie) {
    const breakpoint = bp.getBreakpointSize();
    const dbp = ContextualSidebar.isDesktopBreakpoint();
    const supportedSizes = ['xs', 'sm', 'md'];

    if (this.$sidebar.length) {
      this.$sidebar.toggleClass(`sidebar-collapsed-desktop ${SIDEBAR_COLLAPSED_CLASS}`, collapsed);
      this.$sidebar.toggleClass('sidebar-expanded-mobile', !dbp ? !collapsed : false);
      this.$page.toggleClass(
        'page-with-icon-sidebar',
        supportedSizes.includes(breakpoint) ? true : collapsed,
      );
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

    if (!ContextualSidebar.isDesktopBreakpoint()) {
      this.toggleSidebarNav(false);
    } else {
      const collapse = parseBoolean(Cookies.get('sidebar_collapsed'));
      this.toggleCollapsedSidebar(collapse, true);
    }
  }
}
