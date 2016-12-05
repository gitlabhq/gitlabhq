/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, no-use-before-define, no-param-reassign, quotes, yoda, no-else-return, consistent-return, comma-dangle, semi, object-shorthand, prefer-template, one-var, one-var-declaration-per-line, no-unused-vars, max-len, vars-on-top, padded-blocks */
/* global Breakpoints */
/* global Turbolinks */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Build = (function() {
    Build.interval = null;

    Build.state = null;

    function isInViewport(el) {
      // Courtesy http://stackoverflow.com/a/7557433/414749
      var rect = el[0].getBoundingClientRect();

      return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= $(window).height() &&
        rect.right <= $(window).width()
      );
    }

    function Build(options) {
      options = options || $('.js-build-options').data();
      this.pageUrl = options.pageUrl;
      this.buildUrl = options.buildUrl;
      this.buildStatus = options.buildStatus;
      this.state = options.logState;
      this.buildStage = options.buildStage;
      this.updateDropdown = bind(this.updateDropdown, this);
      this.$document = $(document);
      clearInterval(Build.interval);
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
      if (this.buildStatus === "running" || this.buildStatus === "pending") {
        Build.interval = setInterval((function(_this) {
          // Check for new build output if user still watching build page
          // Only valid for runnig build when output changes during time
          return function() {
            if (_this.location() === _this.pageUrl) {
              return _this.getBuildTrace();
            }
          };
        })(this), 4000);
      }
    }

    Build.prototype.initSidebar = function() {
      this.$sidebar = $('.js-build-sidebar');
      this.sidebarTranslationLimits = {
        min: $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight()
      }
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

    Build.prototype.getInitialBuildTrace = function() {
      var removeRefreshStatuses = ['success', 'failed', 'canceled', 'skipped']

      return $.ajax({
        url: this.buildUrl,
        dataType: 'json',
        success: function(buildData) {
          $('.js-build-output').html(buildData.trace_html);
          if (removeRefreshStatuses.indexOf(buildData.status) >= 0) {
            return $('.js-build-refresh').remove();
          }
        }
      });
    };

    Build.prototype.getBuildTrace = function() {
      return $.ajax({
        url: this.pageUrl + "/trace.json?state=" + (encodeURIComponent(this.state)),
        dataType: "json",
        success: (function(_this) {
          return function(log) {
            if (log.state) {
              _this.state = log.state;
            }
            if (log.status === "running") {
              if (log.append) {
                $('.js-build-output').append(log.html);
              } else {
                $('.js-build-output').html(log.html);
              }
              return _this.checkAutoscroll();
            } else if (log.status !== _this.buildStatus) {
              return Turbolinks.visit(_this.pageUrl);
            }
          };
        })(this)
      });
    };

    Build.prototype.checkAutoscroll = function() {
      if ("enabled" === $("#autoscroll-status").data("state")) {
        return $("html,body").scrollTop($("#build-trace").height());
      }
    };

    Build.prototype.initScrollButtonAffix = function() {
      var $body = $('body');
      var $buildTrace = $('#build-trace');
      var $scrollTopBtn = $('#scroll-top');
      var $scrollBottomBtn = $('#scroll-bottom');
      var $autoScrollContainer = $('.autoscroll-container');

      $scrollTopBtn.hide().removeClass('sticky');
      $scrollBottomBtn.show().addClass('sticky');

      if ($autoScrollContainer.length) {
        $scrollBottomBtn.hide();
        $autoScrollContainer.show().css({ bottom: 50 });
      }
    }

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
      var $body = $('body');
      var $buildTrace = $('#build-trace');
      var $autoScrollContainer = $('.autoscroll-container');
      var $autoScrollStatus = $('#autoscroll-status');
      var $upBuildTrace = $('#up-build-trace');
      var $downBuildTrace = $('#down-build-trace');
      var $scrollTopBtn = $('#scroll-top');
      var $scrollBottomBtn = $('#scroll-bottom');

      if (isInViewport($upBuildTrace)) { // User is at Top of Build Log
        $scrollTopBtn.hide().removeClass('sticky');
        $scrollBottomBtn.show().addClass('sticky');
      }

      if (isInViewport($downBuildTrace)) { // User is at Bottom of Build Log
        $scrollTopBtn.show().addClass('sticky');
        $scrollBottomBtn.hide().removeClass('sticky');

        if ($autoScrollContainer.length) { // Show and Reposition Autoscroll Status Message
          $autoScrollContainer.show().css({ top: $body.outerHeight() - 75 });
        }
      }

      if (!isInViewport($upBuildTrace) && !isInViewport($downBuildTrace)) { // User is somewhere in middle of Build Log
        $scrollTopBtn.show().addClass('sticky');
        $scrollBottomBtn.show().addClass('sticky');

        if ($autoScrollContainer.length) {
          $autoScrollContainer.hide();
        }
      }

      if (this.buildStatus === "running" || this.buildStatus === "pending") {
        if (isInViewport($('.js-build-refresh'))) { // Check if Refresh Animation is in Viewport
          if ($autoScrollStatus.data("state") === 'disabled') {
            $autoScrollStatus.data("state", 'enabled'); // Enable Autoscroll
          }
        } else {
          if ($autoScrollStatus.data("state") === 'enabled') {
            $autoScrollStatus.data("state", 'disabled'); // Disable Autoscroll
          }
        }
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
