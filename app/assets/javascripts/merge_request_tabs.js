// MergeRequestTabs
//
// Handles persisting and restoring the current tab selection and lazily-loading
// content on the MergeRequests#show page.
//
/*= require js.cookie */

//
// ### Example Markup
//
//   <ul class="nav-links merge-request-tabs">
//     <li class="notes-tab active">
//       <a data-action="notes" data-target="#notes" data-toggle="tab" href="/foo/bar/merge_requests/1">
//         Discussion
//       </a>
//     </li>
//     <li class="commits-tab">
//       <a data-action="commits" data-target="#commits" data-toggle="tab" href="/foo/bar/merge_requests/1/commits">
//         Commits
//       </a>
//     </li>
//     <li class="diffs-tab">
//       <a data-action="diffs" data-target="#diffs" data-toggle="tab" href="/foo/bar/merge_requests/1/diffs">
//         Diffs
//       </a>
//     </li>
//   </ul>
//
//   <div class="tab-content">
//     <div class="notes tab-pane active" id="notes">
//       Notes Content
//     </div>
//     <div class="commits tab-pane" id="commits">
//       Commits Content
//     </div>
//     <div class="diffs tab-pane" id="diffs">
//       Diffs Content
//     </div>
//   </div>
//
//   <div class="mr-loading-status">
//     <div class="loading">
//       Loading Animation
//     </div>
//   </div>
//
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.MergeRequestTabs = (function() {
    MergeRequestTabs.prototype.diffsLoaded = false;

    MergeRequestTabs.prototype.buildsLoaded = false;

    MergeRequestTabs.prototype.pipelinesLoaded = false;

    MergeRequestTabs.prototype.commitsLoaded = false;

    MergeRequestTabs.prototype.fixedLayoutPref = null;

    function MergeRequestTabs(opts) {
      this.opts = opts != null ? opts : {};
      this.opts.setUrl = this.opts.setUrl !== undefined ? this.opts.setUrl : true;

      this.buildsLoaded = this.opts.buildsLoaded || false;

      this.setCurrentAction = bind(this.setCurrentAction, this);
      this.tabShown = bind(this.tabShown, this);
      this.showTab = bind(this.showTab, this);
      // Store the `location` object, allowing for easier stubbing in tests
      this._location = location;
      this.bindEvents();
      this.activateTab(this.opts.action);
      this.initAffix();
    }

    MergeRequestTabs.prototype.bindEvents = function() {
      $(document).on('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown);
      $(document).on('click', '.js-show-tab', this.showTab);
    };

    MergeRequestTabs.prototype.unbindEvents = function() {
      $(document).off('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown);
      $(document).off('click', '.js-show-tab', this.showTab);
    };

    MergeRequestTabs.prototype.showTab = function(event) {
      event.preventDefault();
      return this.activateTab($(event.target).data('action'));
    };

    MergeRequestTabs.prototype.tabShown = function(event) {
      var $target, action, navBarHeight;
      $target = $(event.target);
      action = $target.data('action');
      if (action === 'commits') {
        this.loadCommits($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else if (this.isDiffAction(action)) {
        this.loadDiff($target.attr('href'));
        if ((typeof bp !== "undefined" && bp !== null) && bp.getBreakpointSize() !== 'lg') {
          this.shrinkView();
        }
        if (this.diffViewType() === 'parallel') {
          this.expandViewContainer();
        }
        navBarHeight = $('.navbar-gitlab').outerHeight();
        $.scrollTo(".merge-request-details .merge-request-tabs", {
          offset: -navBarHeight
        });
      } else if (action === 'builds') {
        this.loadBuilds($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else if (action === 'pipelines') {
        this.loadPipelines($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else {
        this.expandView();
        this.resetViewContainer();
      }
      if (this.opts.setUrl) {
        this.setCurrentAction(action);
      }
    };

    MergeRequestTabs.prototype.scrollToElement = function(container) {
      var $el, navBarHeight;
      if (window.location.hash) {
        navBarHeight = $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight();
        $el = $(container + " " + window.location.hash + ":not(.match)");
        if ($el.length) {
          return $.scrollTo(container + " " + window.location.hash + ":not(.match)", {
            offset: -navBarHeight
          });
        }
      }
    };

    // Activate a tab based on the current action
    MergeRequestTabs.prototype.activateTab = function(action) {
      if (action === 'show') {
        action = 'notes';
      }
      $(".merge-request-tabs a[data-action='" + action + "']").tab('show').trigger('shown.bs.tab');
    };

    // Replaces the current Merge Request-specific action in the URL with a new one
    //
    // If the action is "notes", the URL is reset to the standard
    // `MergeRequests#show` route.
    //
    // Examples:
    //
    //   location.pathname # => "/namespace/project/merge_requests/1"
    //   setCurrentAction('diffs')
    //   location.pathname # => "/namespace/project/merge_requests/1/diffs"
    //
    //   location.pathname # => "/namespace/project/merge_requests/1/diffs"
    //   setCurrentAction('notes')
    //   location.pathname # => "/namespace/project/merge_requests/1"
    //
    //   location.pathname # => "/namespace/project/merge_requests/1/diffs"
    //   setCurrentAction('commits')
    //   location.pathname # => "/namespace/project/merge_requests/1/commits"
    //
    // Returns the new URL String
    MergeRequestTabs.prototype.setCurrentAction = function(action) {
      var new_state;
      // Normalize action, just to be safe
      if (action === 'show') {
        action = 'notes';
      }
      this.currentAction = action;
      // Remove a trailing '/commits' '/diffs' '/builds' '/pipelines' '/new' '/new/diffs'
      new_state = this._location.pathname.replace(/\/(commits|diffs|builds|pipelines|new|new\/diffs)(\.html)?\/?$/, '');

      // Append the new action if we're on a tab other than 'notes'
      if (action !== 'notes') {
        new_state += "/" + action;
      }
      // Ensure parameters and hash come along for the ride
      new_state += this._location.search + this._location.hash;
      history.replaceState({
        turbolinks: true,
        url: new_state
      // Replace the current history state with the new one without breaking
      // Turbolinks' history.
      //
      // See https://github.com/rails/turbolinks/issues/363
      }, document.title, new_state);
      return new_state;
    };

    MergeRequestTabs.prototype.loadCommits = function(source) {
      if (this.commitsLoaded) {
        return;
      }
      return this._get({
        url: source + ".json",
        success: (function(_this) {
          return function(data) {
            document.querySelector("div#commits").innerHTML = data.html;
            gl.utils.localTimeAgo($('.js-timeago', 'div#commits'));
            _this.commitsLoaded = true;
            return _this.scrollToElement("#commits");
          };
        })(this)
      });
    };

    MergeRequestTabs.prototype.loadDiff = function(source) {
      if (this.diffsLoaded) {
        return;
      }

      // We extract pathname for the current Changes tab anchor href
      // some pages like MergeRequestsController#new has query parameters on that anchor
      var url = gl.utils.parseUrl(source);

      return this._get({
        url: (url.pathname + ".json") + this._location.search,
        success: (function(_this) {
          return function(data) {
            $('#diffs').html(data.html);

            if (typeof DiffNotesApp !== 'undefined') {
              DiffNotesApp.compileComponents();
            }

            gl.utils.localTimeAgo($('.js-timeago', 'div#diffs'));
            $('#diffs .js-syntax-highlight').syntaxHighlight();
            $('#diffs .diff-file').singleFileDiff();
            if (_this.diffViewType() === 'parallel' && (_this.isDiffAction(_this.currentAction)) ) {
              _this.expandViewContainer();
            }
            _this.diffsLoaded = true;
            _this.scrollToElement("#diffs");
            _this.highlighSelectedLine();
            _this.filesCommentButton = $('.files .diff-file').filesCommentButton();
            return $(document).off('click', '.diff-line-num a').on('click', '.diff-line-num a', function(e) {
              e.preventDefault();
              window.location.hash = $(e.currentTarget).attr('href');
              _this.highlighSelectedLine();
              return _this.scrollToElement("#diffs");
            });
          };
        })(this)
      });
    };

    MergeRequestTabs.prototype.highlighSelectedLine = function() {
      var $diffLine, diffLineTop, hashClassString, locationHash, navBarHeight;
      $('.hll').removeClass('hll');
      locationHash = window.location.hash;
      if (locationHash !== '') {
        dataLineString = '[data-line-code="' + locationHash.replace('#', '') + '"]';
        $diffLine = $(locationHash + ":not(.match)", $('#diffs'));
        if (!$diffLine.is('tr')) {
          $diffLine = $('#diffs').find("td" + locationHash + ", td" + dataLineString);
        } else {
          $diffLine = $diffLine.find('td');
        }
        if ($diffLine.length) {
          $diffLine.addClass('hll');
          diffLineTop = $diffLine.offset().top;
          return navBarHeight = $('.navbar-gitlab').outerHeight();
        }
      }
    };

    MergeRequestTabs.prototype.loadBuilds = function(source) {
      if (this.buildsLoaded) {
        return;
      }
      return this._get({
        url: source + ".json",
        success: (function(_this) {
          return function(data) {
            document.querySelector("div#builds").innerHTML = data.html;
            gl.utils.localTimeAgo($('.js-timeago', 'div#builds'));
            _this.buildsLoaded = true;
            if (!this.pipelines) this.pipelines = new gl.Pipelines();
            return _this.scrollToElement("#builds");
          };
        })(this)
      });
    };

    MergeRequestTabs.prototype.loadPipelines = function(source) {
      if (this.pipelinesLoaded) {
        return;
      }
      return this._get({
        url: source + ".json",
        success: function(data) {
          $('#pipelines').html(data.html);
          gl.utils.localTimeAgo($('.js-timeago', '#pipelines'));
          this.pipelinesLoaded = true;
          return this.scrollToElement("#pipelines");
        }.bind(this)
      });
    };

    // Show or hide the loading spinner
    //
    // status - Boolean, true to show, false to hide
    MergeRequestTabs.prototype.toggleLoading = function(status) {
      return $('.mr-loading-status .loading').toggle(status);
    };

    MergeRequestTabs.prototype._get = function(options) {
      var defaults;
      defaults = {
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
        type: 'GET'
      };
      options = $.extend({}, defaults, options);
      return $.ajax(options);
    };

    MergeRequestTabs.prototype.diffViewType = function() {
      return $('.inline-parallel-buttons a.active').data('view-type');
    };

    MergeRequestTabs.prototype.isDiffAction = function(action) {
      return action === 'diffs' || action === 'new/diffs'
    };

    MergeRequestTabs.prototype.expandViewContainer = function() {
      var $wrapper = $('.content-wrapper .container-fluid');
      if (this.fixedLayoutPref === null) {
        this.fixedLayoutPref = $wrapper.hasClass('container-limited');
      }
      $wrapper.removeClass('container-limited');
    };

    MergeRequestTabs.prototype.resetViewContainer = function() {
      if (this.fixedLayoutPref !== null) {
        $('.content-wrapper .container-fluid')
          .toggleClass('container-limited', this.fixedLayoutPref);
      }
    };

    MergeRequestTabs.prototype.shrinkView = function() {
      var $gutterIcon;
      $gutterIcon = $('.js-sidebar-toggle i:visible');
      return setTimeout(function() {
        if ($gutterIcon.is('.fa-angle-double-right')) {
          return $gutterIcon.closest('a').trigger('click', [true]);
        }
      // Wait until listeners are set
      // Only when sidebar is expanded
      }, 0);
    };

    MergeRequestTabs.prototype.expandView = function() {
      var $gutterIcon;
      if (Cookies.get('collapsed_gutter') === 'true') {
        return;
      }
      $gutterIcon = $('.js-sidebar-toggle i:visible');
      return setTimeout(function() {
        if ($gutterIcon.is('.fa-angle-double-left')) {
          return $gutterIcon.closest('a').trigger('click', [true]);
        }
      }, 0);
    // Expand the issuable sidebar unless the user explicitly collapsed it
    // Wait until listeners are set
    // Only when sidebar is collapsed
    };

    MergeRequestTabs.prototype.initAffix = function () {
      var $tabs = $('.js-tabs-affix');

      // Screen space on small screens is usually very sparse
      // So we dont affix the tabs on these
      if (Breakpoints.get().getBreakpointSize() === 'xs' || !$tabs.length) return;

      var $diffTabs = $('#diff-notes-app'),
        $fixedNav = $('.navbar-fixed-top'),
        $layoutNav = $('.layout-nav');

      $tabs.off('affix.bs.affix affix-top.bs.affix')
        .affix({
          offset: {
            top: function () {
              var tabsTop = $diffTabs.offset().top - $tabs.height();
              tabsTop = tabsTop - ($fixedNav.height() + $layoutNav.height());

              return tabsTop;
            }
          }
        }).on('affix.bs.affix', function () {
          $diffTabs.css({
            marginTop: $tabs.height()
          });
        }).on('affix-top.bs.affix', function () {
          $diffTabs.css({
            marginTop: ''
          });
        });

      // Fix bug when reloading the page already scrolling
      if ($tabs.hasClass('affix')) {
        $tabs.trigger('affix.bs.affix');
      }
    };

    return MergeRequestTabs;

  })();

}).call(this);
