/* eslint-disable */
((global) => {
  let singleton;

  const pinnedStateCookie = 'pin_nav';
  const sidebarBreakpoint = 1024;

  const pageSelector = '.page-with-sidebar';
  const navbarSelector = '.navbar-fixed-top';
  const sidebarWrapperSelector = '.sidebar-wrapper';
  const sidebarContentSelector = '.nav-sidebar';

  const pinnedToggleSelector = '.js-nav-pin';
  const sidebarToggleSelector = '.toggle-nav-collapse, .side-nav-toggle';

  const pinnedPageClass = 'page-sidebar-pinned';
  const expandedPageClass = 'page-sidebar-expanded';

  const pinnedNavbarClass = 'header-sidebar-pinned';
  const expandedNavbarClass = 'header-sidebar-expanded';

  class Sidebar {
    constructor() {
      if (!singleton) {
        singleton = this;
        singleton.init();
      }
      return singleton;
    }

    init() {
      this.isPinned = Cookies.get(pinnedStateCookie) === 'true';
      this.isExpanded = (
        window.innerWidth >= sidebarBreakpoint &&
        $(pageSelector).hasClass(expandedPageClass)
      );
      $(document)
        .on('click', sidebarToggleSelector, () => this.toggleSidebar())
        .on('click', pinnedToggleSelector, () => this.togglePinnedState())
        .on('click', 'html, body', (e) => this.handleClickEvent(e))
        .on('page:change', () => this.renderState())
        .on('todo:toggle', (e, count) => this.updateTodoCount(count));
      this.renderState();
    }

    handleClickEvent(e) {
      if (this.isExpanded && (!this.isPinned || window.innerWidth < sidebarBreakpoint)) {
        const $target = $(e.target);
        const targetIsToggle = $target.closest(sidebarToggleSelector).length > 0;
        const targetIsSidebar = $target.closest(sidebarWrapperSelector).length > 0;
        if (!targetIsToggle && (!targetIsSidebar || $target.closest('a'))) {
          this.toggleSidebar();
        }
      }
    }

    updateTodoCount(count) {
      $('.js-todos-count').text(gl.text.addDelimiter(count));
    }

    toggleSidebar() {
      this.isExpanded = !this.isExpanded;
      this.renderState();
    }

    togglePinnedState() {
      this.isPinned = !this.isPinned;
      if (!this.isPinned) {
        this.isExpanded = false;
      }
      Cookies.set(pinnedStateCookie, this.isPinned ? 'true' : 'false', { expires: 3650 });
      this.renderState();
    }

    renderState() {
      $(pageSelector)
        .toggleClass(pinnedPageClass, this.isPinned && this.isExpanded)
        .toggleClass(expandedPageClass, this.isExpanded);
      $(navbarSelector)
        .toggleClass(pinnedNavbarClass, this.isPinned && this.isExpanded)
        .toggleClass(expandedNavbarClass, this.isExpanded);

      const $pinnedToggle = $(pinnedToggleSelector);
      const tooltipText = this.isPinned ? 'Unpin navigation' : 'Pin navigation';
      const tooltipState = $pinnedToggle.attr('aria-describedby') && this.isExpanded ? 'show' : 'hide';
      $pinnedToggle.attr('title', tooltipText).tooltip('fixTitle').tooltip(tooltipState);

      if (this.isExpanded) {
        setTimeout(() => $(sidebarContentSelector).niceScroll().updateScrollBar(), 200);
      }
    }
  }

  global.Sidebar = Sidebar;

})(window.gl || (window.gl = {}));
