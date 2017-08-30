import Cookies from 'js-cookie';
import _ from 'underscore';
import bp from './breakpoints';

export default class NewNavSidebar {
  constructor() {
    this.initDomElements();
    this.render();
  }

  initDomElements() {
    this.$page = $('.page-with-sidebar');
    this.$sidebar = $('.nav-sidebar');
    this.$overlay = $('.mobile-overlay');
    this.$openSidebar = $('.toggle-mobile-nav');
    this.$closeSidebar = $('.close-nav-button');
    this.$sidebarToggle = $('.js-toggle-sidebar');
  }

  bindEvents() {
    this.$openSidebar.on('click', () => this.toggleSidebarNav(true));
    this.$closeSidebar.on('click', () => this.toggleSidebarNav(false));
    this.$overlay.on('click', () => this.toggleSidebarNav(false));
    this.$sidebarToggle.on('click', () => {
      const value = !this.$sidebar.hasClass('sidebar-icons-only');
      this.toggleCollapsedSidebar(value);
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
    this.$sidebar.toggleClass('nav-sidebar-expanded', show);
    this.$overlay.toggleClass('mobile-nav-open', show);
    this.$sidebar.removeClass('sidebar-icons-only');
  }

  toggleCollapsedSidebar(collapsed) {
    const breakpoint = bp.getBreakpointSize();

    if (this.$sidebar.length) {
      this.$sidebar.toggleClass('sidebar-icons-only', collapsed);
      this.$page.toggleClass('page-with-icon-sidebar', breakpoint === 'sm' ? true : collapsed);
    }
    NewNavSidebar.setCollapsedCookie(collapsed);
  }

  render() {
    const breakpoint = bp.getBreakpointSize();

    if (breakpoint === 'sm' || breakpoint === 'md') {
      this.toggleCollapsedSidebar(true);
    } else if (breakpoint === 'lg') {
      const collapse = Cookies.get('sidebar_collapsed') === 'true';
      this.toggleCollapsedSidebar(collapse);
    }
  }
}
