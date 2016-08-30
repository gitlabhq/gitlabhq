(function() {
  this.User = (function() {
    function User(opts) {
      this.opts = opts;
      $('.profile-groups-avatars').tooltip({
        "placement": "top"
      });
      this.initTabs();
      $('.hide-project-limit-message').on('click', function(e) {
        $.cookie('hide_project_limit_message', 'false', {
          path: gon.relative_url_root || '/'
        });
        $(this).parents('.project-limit-message').remove();
        return e.preventDefault();
      });
    }

    User.prototype.initTabs = function() {
      return new UserTabs({
        parentEl: '.user-profile',
        action: this.opts.action
      });
    };

    return User;

  })();

}).call(this);
