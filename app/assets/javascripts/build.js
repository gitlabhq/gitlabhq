/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, no-use-before-define, no-param-reassign, no-undef, quotes, yoda, no-else-return, consistent-return, comma-dangle, semi, object-shorthand, prefer-template, one-var, one-var-declaration-per-line, no-unused-vars, max-len, vars-on-top, padded-blocks, max-len */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Build = (function() {
    Build.interval = null;

    Build.state = null;

    function Build(options) {
      options = options || $('.js-build-options').data();
      this.pageUrl = options.pageUrl;
      this.buildUrl = options.buildUrl;
      this.buildStatus = options.buildStatus;
      this.state = options.state1;
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
      $(window).off('resize.build').on('resize.build', this.sidebarOnResize.bind(this));
      $('a', this.$buildScroll).off('click.stepTrace').on('click.stepTrace', this.stepTrace);
      this.updateArtifactRemoveDate();
      if ($('#build-trace').length) {
        this.getInitialBuildTrace();
        this.initScrollButtonAffix();
      }
      if (this.buildStatus === "running" || this.buildStatus === "pending") {
        // Bind autoscroll button to follow build output
        $('#autoscroll-button').on('click', function() {
          var state;
          state = $(this).data("state");
          if ("enabled" === state) {
            $(this).data("state", "disabled");
            return $(this).text("Enable autoscroll");
          } else {
            $(this).data("state", "enabled");
            return $(this).text("Disable autoscroll");
          }
        });
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
      if ("enabled" === $("#autoscroll-button").data("state")) {
        return $("html,body").scrollTop($("#build-trace").height());
      }
    };

    Build.prototype.initScrollButtonAffix = function() {
      var $body, $buildTrace;
      $body = $('body');
      $buildTrace = $('#build-trace');
      return this.$buildScroll.affix({
        offset: {
          bottom: function() {
            return $body.outerHeight() - ($buildTrace.outerHeight() + $buildTrace.offset().top);
          }
        }
      });
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
      e.preventDefault();
      $currentTarget = $(e.currentTarget);
      $.scrollTo($currentTarget.attr('href'), {
        offset: -($('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight())
      });
    };

    return Build;

  })();

}).call(this);
