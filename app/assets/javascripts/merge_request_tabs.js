
/*= require jquery.cookie */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.MergeRequestTabs = (function() {
    MergeRequestTabs.prototype.diffsLoaded = false;

    MergeRequestTabs.prototype.buildsLoaded = false;

    MergeRequestTabs.prototype.commitsLoaded = false;

    function MergeRequestTabs(opts) {
      this.opts = opts != null ? opts : {};
      this.setCurrentAction = bind(this.setCurrentAction, this);
      this.tabShown = bind(this.tabShown, this);
      this.showTab = bind(this.showTab, this);
      this._location = location;
      this.bindEvents();
      this.activateTab(this.opts.action);
    }

    MergeRequestTabs.prototype.bindEvents = function() {
      $(document).on('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown);
      return $(document).on('click', '.js-show-tab', this.showTab);
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
      } else if (action === 'diffs') {
        this.loadDiff($target.attr('href'));
        if ((typeof bp !== "undefined" && bp !== null) && bp.getBreakpointSize() !== 'lg') {
          this.shrinkView();
        }
        navBarHeight = $('.navbar-gitlab').outerHeight();
        $.scrollTo(".merge-request-details .merge-request-tabs", {
          offset: -navBarHeight
        });
      } else if (action === 'builds') {
        this.loadBuilds($target.attr('href'));
        this.expandView();
      } else {
        this.expandView();
      }
      return this.setCurrentAction(action);
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

    MergeRequestTabs.prototype.activateTab = function(action) {
      if (action === 'show') {
        action = 'notes';
      }
      return $(".merge-request-tabs a[data-action='" + action + "']").tab('show');
    };

    MergeRequestTabs.prototype.setCurrentAction = function(action) {
      var new_state;
      if (action === 'show') {
        action = 'notes';
      }
      new_state = this._location.pathname.replace(/\/(commits|diffs|builds)(\.html)?\/?$/, '');
      if (action !== 'notes') {
        new_state += "/" + action;
      }
      new_state += this._location.search + this._location.hash;
      history.replaceState({
        turbolinks: true,
        url: new_state
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
      return this._get({
        url: (source + ".json") + this._location.search,
        success: (function(_this) {
          return function(data) {
            $('#diffs').html(data.html);

            if (compileVueComponentsForDiffNotes) {
              compileVueComponentsForDiffNotes();
            }

            gl.utils.localTimeAgo($('.js-timeago', 'div#diffs'));
            $('#diffs .js-syntax-highlight').syntaxHighlight();
            $('#diffs .diff-file').singleFileDiff();
            if (_this.diffViewType() === 'parallel') {
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
        hashClassString = "." + (locationHash.replace('#', ''));
        $diffLine = $(locationHash + ":not(.match)", $('#diffs'));
        if (!$diffLine.is('tr')) {
          $diffLine = $('#diffs').find("td" + locationHash + ", td" + hashClassString);
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
            return _this.scrollToElement("#builds");
          };
        })(this)
      });
    };

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

    MergeRequestTabs.prototype.expandViewContainer = function() {
      return $('.container-fluid').removeClass('container-limited');
    };

    MergeRequestTabs.prototype.shrinkView = function() {
      var $gutterIcon;
      $gutterIcon = $('.js-sidebar-toggle i:visible');
      return setTimeout(function() {
        if ($gutterIcon.is('.fa-angle-double-right')) {
          return $gutterIcon.closest('a').trigger('click', [true]);
        }
      }, 0);
    };

    MergeRequestTabs.prototype.expandView = function() {
      var $gutterIcon;
      if ($.cookie('collapsed_gutter') === 'true') {
        return;
      }
      $gutterIcon = $('.js-sidebar-toggle i:visible');
      return setTimeout(function() {
        if ($gutterIcon.is('.fa-angle-double-left')) {
          return $gutterIcon.closest('a').trigger('click', [true]);
        }
      }, 0);
    };

    return MergeRequestTabs;

  })();

}).call(this);
