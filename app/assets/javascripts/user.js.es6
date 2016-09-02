(global => {
  global.User = class {
    constructor(opts) {
      this.opts = opts;
      this.placeProfileAvatarsToTop();
      this.initTabs();
      this.hideProjectLimitMessage();
    }

    placeProfileAvatarsToTop() {
      $('.profile-groups-avatars').tooltip({
        placement: 'top'
      });
    }

    initTabs() {
      return new UserTabs({
        parentEl: '.user-profile',
        action: this.opts.action
      });
    }

    hideProjectLimitMessage() {
      $('.hide-project-limit-message').on('click', e => {
        e.preventDefault();
        const path = gon.relative_url_root || '/';
        $.cookie('hide_project_limit_message', 'false', {
          path: path
        });
        $(this).parents('.project-limit-message').remove();
      });
    }
  }
})(window.gl || (window.gl = {}));
