export default class NewNavSidebar {
  constructor() {
    this.initDomElements();
    this.bindEvents();
  }

  initDomElements() {
    this.$sidebar = $('.nav-sidebar');
    this.$overlay = $('.mobile-overlay');
    this.$openSidebar = $('.toggle-mobile-nav');
    this.$closeSidebar = $('.close-nav-button');
  }

  bindEvents() {
    this.$openSidebar.on('click', e => this.toggleSidebarNav(e, true));
    this.$closeSidebar.on('click', e => this.toggleSidebarNav(e, false));
    this.$overlay.on('click', e => this.toggleSidebarNav(e, false));
  }

  toggleSidebarNav(show) {
    this.$sidebar.toggleClass('nav-sidebar-expanded', show);
    this.$overlay.toggleClass('mobile-nav-open', show);
  }
}
