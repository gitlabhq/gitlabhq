(global => {
  global.User = class {
    constructor(opts) {
      this.opts = opts;
      this.placeTop();
      this.initTabs();
      this.hideProjectLimitMessage();
    }

    placeTop() {
      $('.profile-groups-avatars').tooltip({
        "placement": "top"
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
        const path = '/';
        $.cookie('hide_project_limit_message', 'false', {
          path: path
        });
        $(this).parents('.project-limit-message').remove();
        e.preventDefault();
        return;
      });
    }
  }
})(window.gl || (window.gl = {}));
