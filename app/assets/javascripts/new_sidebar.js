const SIDEBAR_EXPANDED_CLASS = 'nav-sidebar-expanded';

export default class NewNavSidebar {
  constructor() {
    this.initDomElements();
    this.bindEvents();
  }

  initDomElements() {
    this.$sidebar = $('.nav-sidebar');
    this.$openSidebar = $('.toggle-mobile-nav');
    this.$closeSidebar = $('.close-nav-button');
  }

  bindEvents() {
    this.$openSidebar.on('click', e => this.toggleSidebarNav(e, true));
    this.$closeSidebar.on('click', e => this.toggleSidebarNav(e, false));
  }

  toggleSidebarNav(show) {
    this.$sidebar.toggleClass(SIDEBAR_EXPANDED_CLASS, show);
  }
}
