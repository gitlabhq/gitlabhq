(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.UserTabs = (function() {
    function UserTabs(opts) {
      this.tabShown = bind(this.tabShown, this);
      var i, item, len, ref, ref1, ref2, ref3;
      this.action = (ref = opts.action) != null ? ref : 'activity', this.defaultAction = (ref1 = opts.defaultAction) != null ? ref1 : 'activity', this.parentEl = (ref2 = opts.parentEl) != null ? ref2 : $(document);
      if (typeof this.parentEl === 'string') {
        this.parentEl = $(this.parentEl);
      }
      this._location = location;
      this.loaded = {};
      ref3 = this.parentEl.find('.nav-links a');
      for (i = 0, len = ref3.length; i < len; i++) {
        item = ref3[i];
        this.loaded[$(item).attr('data-action')] = false;
      }
      this.actions = Object.keys(this.loaded);
      this.bindEvents();
      if (this.action === 'show') {
        this.action = this.defaultAction;
      }
      this.activateTab(this.action);
    }

    UserTabs.prototype.bindEvents = function() {
      return this.parentEl.off('shown.bs.tab', '.nav-links a[data-toggle="tab"]').on('shown.bs.tab', '.nav-links a[data-toggle="tab"]', this.tabShown);
    };

    UserTabs.prototype.tabShown = function(event) {
      var $target, action, source;
      $target = $(event.target);
      action = $target.data('action');
      source = $target.attr('href');
      this.setTab(source, action);
      return this.setCurrentAction(action);
    };

    UserTabs.prototype.activateTab = function(action) {
      return this.parentEl.find(".nav-links .js-" + action + "-tab a").tab('show');
    };

    UserTabs.prototype.setTab = function(source, action) {
      if (this.loaded[action] === true) {
        return;
      }
      if (action === 'activity') {
        this.loadActivities(source);
      }
      if (action === 'groups' || action === 'contributed' || action === 'projects' || action === 'snippets') {
        return this.loadTab(source, action);
      }
    };

    UserTabs.prototype.loadTab = function(source, action) {
      return $.ajax({
        beforeSend: (function(_this) {
          return function() {
            return _this.toggleLoading(true);
          };
        })(this),
        complete: (function(_this) {
          return function() {
            return _this.toggleLoading(false);
          };
        })(this),
        dataType: 'json',
        type: 'GET',
        url: source + ".json",
        success: (function(_this) {
          return function(data) {
            var tabSelector;
            tabSelector = 'div#' + action;
            _this.parentEl.find(tabSelector).html(data.html);
            _this.loaded[action] = true;
            return gl.utils.localTimeAgo($('.js-timeago', tabSelector));
          };
        })(this)
      });
    };

    UserTabs.prototype.loadActivities = function(source) {
      var $calendarWrap;
      if (this.loaded['activity'] === true) {
        return;
      }
      $calendarWrap = this.parentEl.find('.user-calendar');
      $calendarWrap.load($calendarWrap.data('href'));
      new Activities();
      return this.loaded['activity'] = true;
    };

    UserTabs.prototype.toggleLoading = function(status) {
      return this.parentEl.find('.loading-status .loading').toggle(status);
    };

    UserTabs.prototype.setCurrentAction = function(action) {
      var new_state, regExp;
      regExp = new RegExp('\/(' + this.actions.join('|') + ')(\.html)?\/?$');
      new_state = this._location.pathname;
      new_state = new_state.replace(/\/+$/, "");
      new_state = new_state.replace(regExp, '');
      if (action !== this.defaultAction) {
        new_state += "/" + action;
      }
      new_state += this._location.search + this._location.hash;
      history.replaceState({
        turbolinks: true,
        url: new_state
      }, document.title, new_state);
      return new_state;
    };

    return UserTabs;

  })();

}).call(this);
