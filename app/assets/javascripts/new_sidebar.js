export default class NewNavSidebar {
  constructor() {
    this.initDomElements();
  }

  initDomElements() {
    this.$sidebar = $('.nav-sidebar');
    this.$overlay = $('.mobile-overlay');
    this.$openSidebar = $('.toggle-mobile-nav');
    this.$closeSidebar = $('.close-nav-button');
  }

  bindEvents() {
    this.$openSidebar.on('click', () => this.toggleSidebarNav(true));
    this.$closeSidebar.on('click', () => this.toggleSidebarNav(false));
    this.$overlay.on('click', () => this.toggleSidebarNav(false));
  }

  toggleSidebarNav(show) {
    this.$sidebar.toggleClass('nav-sidebar-expanded', show);
    this.$overlay.toggleClass('mobile-nav-open', show);
  }
}
