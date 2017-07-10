export default {
  init() {
    if (!this.initialized) {
      this.$window = $(window);
      this.$rightSidebar = $('.js-right-sidebar');
      this.$navHeight = $('.navbar-gitlab').outerHeight() +
        $('.layout-nav').outerHeight() +
        $('.sub-nav-scroll').outerHeight();

      const throttledSetSidebarHeight = _.throttle(() => this.setSidebarHeight(), 20);
      const debouncedSetSidebarHeight = _.debounce(() => this.setSidebarHeight(), 200);

      this.$window.on('scroll', throttledSetSidebarHeight);
      this.$window.on('resize', debouncedSetSidebarHeight);
      this.initialized = true;
    }
  },

  setSidebarHeight() {
    const currentScrollDepth = window.pageYOffset || 0;
    const diff = this.$navHeight - currentScrollDepth;

    if (diff > 0) {
      const newSidebarHeight = window.innerHeight - diff;
      this.$rightSidebar.outerHeight(newSidebarHeight);
      this.sidebarHeightIsCustom = true;
    } else if (this.sidebarHeightIsCustom) {
      this.$rightSidebar.outerHeight('100%');
      this.sidebarHeightIsCustom = false;
    }
  },
};

