/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-use-before-define, no-param-reassign, quotes, yoda, no-else-return, consistent-return, comma-dangle, object-shorthand, prefer-template, one-var, one-var-declaration-per-line, no-unused-vars, max-len, vars-on-top */
/* global Breakpoints */

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };
  var AUTO_SCROLL_OFFSET = 75;
  var DOWN_BUILD_TRACE = '#down-build-trace';

  this.Build = (function() {
    Build.timeout = null;

    Build.state = null;

    function Build(options) {
      options = options || $('.js-build-options').data();
      this.pageUrl = options.pageUrl;
      this.buildUrl = options.buildUrl;
      this.buildStatus = options.buildStatus;
      this.state = options.logState;
      this.buildStage = options.buildStage;
      this.updateDropdown = bind(this.updateDropdown, this);
      this.$document = $(document);
      this.$body = $('body');
      this.$buildTrace = $('#build-trace');
      this.$autoScrollContainer = $('.autoscroll-container');
      this.$autoScrollStatus = $('#autoscroll-status');
      this.$autoScrollStatusText = this.$autoScrollStatus.find('.status-text');
      this.$upBuildTrace = $('#up-build-trace');
      this.$downBuildTrace = $(DOWN_BUILD_TRACE);
      this.$scrollTopBtn = $('#scroll-top');
      this.$scrollBottomBtn = $('#scroll-bottom');
      this.$buildRefreshAnimation = $('.js-build-refresh');

      clearTimeout(Build.timeout);
      // Init breakpoint checker
      this.bp = Breakpoints.get();

      this.initSidebar();
      this.$buildScroll = $('#js-build-scroll');

      this.populateJobs(this.buildStage);
      this.updateStageDropdownText(this.buildStage);
      this.sidebarOnResize();

      this.$document.off('click', '.js-sidebar-build-toggle').on('click', '.js-sidebar-build-toggle', this.sidebarOnClick.bind(this));
      this.$document.off('click', '.stage-item').on('click', '.stage-item', this.updateDropdown);
      this.$document.on('scroll', this.initScrollMonitor.bind(this));
      $(window).off('resize.build').on('resize.build', this.sidebarOnResize.bind(this));
      $('a', this.$buildScroll).off('click.stepTrace').on('click.stepTrace', this.stepTrace);
      this.updateArtifactRemoveDate();
      if ($('#build-trace').length) {
        this.getInitialBuildTrace();
        this.initScrollButtonAffix();
      }
      this.invokeBuildTrace();
    }

    Build.prototype.initSidebar = function() {
      this.$sidebar = $('.js-build-sidebar');
      this.sidebarTranslationLimits = {
        min: $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight()
      };
      this.sidebarTranslationLimits.max = this.sidebarTranslationLimits.min + $('.scrolling-tabs-container').outerHeight();
      this.$sidebar.css({
        top: this.sidebarTranslationLimits.max
      });
      this.$sidebar.niceScroll();
      this.$document.off('click', '.js-sidebar-build-toggle').on('click', '.js-sidebar-build-toggle', this.toggleSidebar);
      this.$document.off('scroll.translateSidebar').on('scroll.translateSidebar', this.translateSidebar.bind(this));
    };

    Build.prototype.location = function() {
      return window.location.href.split("#")[0];
    };

    Build.prototype.invokeBuildTrace = function() {
      var continueRefreshStatuses = ['running', 'pending'];
      // Continue to update build trace when build is running or pending
      if (continueRefreshStatuses.indexOf(this.buildStatus) !== -1) {
        // Check for new build output if user still watching build page
        // Only valid for runnig build when output changes during time
        Build.timeout = setTimeout((function(_this) {
          return function() {
            if (_this.location() === _this.pageUrl) {
              return _this.getBuildTrace();
            }
          };
        })(this), 4000);
      }
    };

    Build.prototype.getInitialBuildTrace = function() {
      var removeRefreshStatuses = ['success', 'failed', 'canceled', 'skipped'];

      return $.ajax({
        url: this.buildUrl,
        dataType: 'json',
        success: function(buildData) {
          $('.js-build-output').html(buildData.trace_html);
          if (window.location.hash === DOWN_BUILD_TRACE) {
            $("html,body").scrollTop(this.$buildTrace.height());
          }
          if (removeRefreshStatuses.indexOf(buildData.status) >= 0) {
            this.$buildRefreshAnimation.remove();
            return this.initScrollMonitor();
          }
        }.bind(this)
      });
    };

    Build.prototype.getBuildTrace = function() {
      return $.ajax({
        url: this.pageUrl + "/trace.json?state=" + (encodeURIComponent(this.state)),
        dataType: "json",
        success: (function(_this) {
          return function(log) {
            var pageUrl;

            if (log.state) {
              _this.state = log.state;
            }
            _this.invokeBuildTrace();
            if (log.status === "running") {
              if (log.append) {
                $('.js-build-output').append(log.html);
              } else {
                $('.js-build-output').html(log.html);
              }
              return _this.checkAutoscroll();
            } else if (log.status !== _this.buildStatus) {
              pageUrl = _this.pageUrl;
              if (_this.$autoScrollStatus.data('state') === 'enabled') {
                pageUrl += DOWN_BUILD_TRACE;
              }

              return gl.utils.visitUrl(pageUrl);
            }
          };
        })(this)
      });
    };

    Build.prototype.checkAutoscroll = function() {
      if (this.$autoScrollStatus.data("state") === "enabled") {
        return $("html,body").scrollTop(this.$buildTrace.height());
      }

      // Handle a situation where user started new build
      // but never scrolled a page
      if (!this.$scrollTopBtn.is(':visible') &&
          !this.$scrollBottomBtn.is(':visible') &&
          !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        this.$scrollBottomBtn.show();
      }
    };

    Build.prototype.initScrollButtonAffix = function() {
      // Hide everything initially
      this.$scrollTopBtn.hide();
      this.$scrollBottomBtn.hide();
      this.$autoScrollContainer.hide();
    };

    // Page scroll listener to detect if user has scrolling page
    // and handle following cases
    // 1) User is at Top of Build Log;
    //      - Hide Top Arrow button
    //      - Show Bottom Arrow button
    //      - Disable Autoscroll and hide indicator (when build is running)
    // 2) User is at Bottom of Build Log;
    //      - Show Top Arrow button
    //      - Hide Bottom Arrow button
    //      - Enable Autoscroll and show indicator (when build is running)
    // 3) User is somewhere in middle of Build Log;
    //      - Show Top Arrow button
    //      - Show Bottom Arrow button
    //      - Disable Autoscroll and hide indicator (when build is running)
    Build.prototype.initScrollMonitor = function() {
      if (!gl.utils.isInViewport(this.$upBuildTrace.get(0)) && !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        // User is somewhere in middle of Build Log

        this.$scrollTopBtn.show();

        if (this.buildStatus === 'success' || this.buildStatus === 'failed') { // Check if Build is completed
          this.$scrollBottomBtn.show();
        } else if (this.$buildRefreshAnimation.is(':visible') && !gl.utils.isInViewport(this.$buildRefreshAnimation.get(0))) {
          this.$scrollBottomBtn.show();
        } else {
          this.$scrollBottomBtn.hide();
        }

        // Hide Autoscroll Status Indicator
        if (this.$scrollBottomBtn.is(':visible')) {
          this.$autoScrollContainer.hide();
          this.$autoScrollStatusText.removeClass('animate');
        } else {
          this.$autoScrollContainer.css({ top: this.$body.outerHeight() - AUTO_SCROLL_OFFSET }).show();
          this.$autoScrollStatusText.addClass('animate');
        }
      } else if (gl.utils.isInViewport(this.$upBuildTrace.get(0)) && !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        // User is at Top of Build Log

        this.$scrollTopBtn.hide();
        this.$scrollBottomBtn.show();

        this.$autoScrollContainer.hide();
        this.$autoScrollStatusText.removeClass('animate');
      } else if ((!gl.utils.isInViewport(this.$upBuildTrace.get(0)) && gl.utils.isInViewport(this.$downBuildTrace.get(0))) ||
                 (this.$buildRefreshAnimation.is(':visible') && gl.utils.isInViewport(this.$buildRefreshAnimation.get(0)))) {
        // User is at Bottom of Build Log

        this.$scrollTopBtn.show();
        this.$scrollBottomBtn.hide();

        // Show and Reposition Autoscroll Status Indicator
        this.$autoScrollContainer.css({ top: this.$body.outerHeight() - AUTO_SCROLL_OFFSET }).show();
        this.$autoScrollStatusText.addClass('animate');
      } else if (gl.utils.isInViewport(this.$upBuildTrace.get(0)) && gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
        // Build Log height is small

        this.$scrollTopBtn.hide();
        this.$scrollBottomBtn.hide();

        // Hide Autoscroll Status Indicator
        this.$autoScrollContainer.hide();
        this.$autoScrollStatusText.removeClass('animate');
      }

      if (this.buildStatus === "running" || this.buildStatus === "pending") {
        // Check if Refresh Animation is in Viewport and enable Autoscroll, disable otherwise.
        this.$autoScrollStatus.data("state", gl.utils.isInViewport(this.$buildRefreshAnimation.get(0)) ? 'enabled' : 'disabled');
      }
    };

    Build.prototype.shouldHideSidebarForViewport = function() {
      var bootstrapBreakpoint;
      bootstrapBreakpoint = this.bp.getBreakpointSize();
      return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
    };

    Build.prototype.translateSidebar = function(e) {
      var newPosition = this.sidebarTranslationLimits.max - (document.body.scrollTop || document.documentElement.scrollTop);
      if (newPosition < this.sidebarTranslationLimits.min) newPosition = this.sidebarTranslationLimits.min;
      this.$sidebar.css({
        top: newPosition
      });
    };

    Build.prototype.toggleSidebar = function(shouldHide) {
      var shouldShow = typeof shouldHide === 'boolean' ? !shouldHide : undefined;
      this.$buildScroll.toggleClass('sidebar-expanded', shouldShow)
        .toggleClass('sidebar-collapsed', shouldHide);
      this.$sidebar.toggleClass('right-sidebar-expanded', shouldShow)
        .toggleClass('right-sidebar-collapsed', shouldHide);
    };

    Build.prototype.sidebarOnResize = function() {
      this.toggleSidebar(this.shouldHideSidebarForViewport());
    };

    Build.prototype.sidebarOnClick = function() {
      if (this.shouldHideSidebarForViewport()) this.toggleSidebar();
    };

    Build.prototype.updateArtifactRemoveDate = function() {
      var $date, date;
      $date = $('.js-artifacts-remove');
      if ($date.length) {
        date = $date.text();
        return $date.text(gl.utils.timeFor(new Date(date.replace(/([0-9]+)-([0-9]+)-([0-9]+)/g, '$1/$2/$3')), ' '));
      }
    };

    Build.prototype.populateJobs = function(stage) {
      $('.build-job').hide();
      $('.build-job[data-stage="' + stage + '"]').show();
    };

    Build.prototype.updateStageDropdownText = function(stage) {
      $('.stage-selection').text(stage);
    };

    Build.prototype.updateDropdown = function(e) {
      e.preventDefault();
      var stage = e.currentTarget.text;
      this.updateStageDropdownText(stage);
      this.populateJobs(stage);
    };

    Build.prototype.stepTrace = function(e) {
      var $currentTarget;
      e.preventDefault();
      $currentTarget = $(e.currentTarget);
      $.scrollTo($currentTarget.attr('href'), {
        offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
      });
    };

    return Build;
  })();
}).call(this);
