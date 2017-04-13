/* eslint-disable func-names, wrap-iife, no-use-before-define,
consistent-return, prefer-rest-params */
/* global Breakpoints */

const bind = function (fn, me) { return function () { return fn.apply(me, arguments); }; };
const AUTO_SCROLL_OFFSET = 75;
const DOWN_BUILD_TRACE = '#down-build-trace';

window.Build = (function () {
  Build.timeout = null;

  Build.state = null;

  function Build(options) {
    this.options = options || $('.js-build-options').data();

    this.pageUrl = this.options.pageUrl;
    this.buildUrl = this.options.buildUrl;
    this.buildStatus = this.options.buildStatus;
    this.state = this.options.logState;
    this.buildStage = this.options.buildStage;
    this.$document = $(document);

    this.updateDropdown = bind(this.updateDropdown, this);

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
    this.$buildScroll = $('#js-build-scroll');
    this.$truncatedInfo = $('.js-truncated-info');

    clearTimeout(Build.timeout);
    // Init breakpoint checker
    this.bp = Breakpoints.get();

    this.initSidebar();
    this.populateJobs(this.buildStage);
    this.updateStageDropdownText(this.buildStage);
    this.sidebarOnResize();

    this.$document
      .off('click', '.js-sidebar-build-toggle')
      .on('click', '.js-sidebar-build-toggle', this.sidebarOnClick.bind(this));

    this.$document
      .off('click', '.stage-item')
      .on('click', '.stage-item', this.updateDropdown);

    this.$document.on('scroll', this.initScrollMonitor.bind(this));

    $(window)
      .off('resize.build')
      .on('resize.build', this.sidebarOnResize.bind(this));

    $('a', this.$buildScroll)
      .off('click.stepTrace')
      .on('click.stepTrace', this.stepTrace);

    this.updateArtifactRemoveDate();
    this.initScrollButtonAffix();
    this.invokeBuildTrace();
  }

  Build.prototype.initSidebar = function () {
    this.$sidebar = $('.js-build-sidebar');
    this.$sidebar.niceScroll();
    this.$document
      .off('click', '.js-sidebar-build-toggle')
      .on('click', '.js-sidebar-build-toggle', this.toggleSidebar);
  };

  Build.prototype.invokeBuildTrace = function () {
    return this.getBuildTrace();
  };

  Build.prototype.getBuildTrace = function () {
    return $.ajax({
      url: `${this.pageUrl}/trace.json`,
      dataType: 'json',
      data: {
        state: this.state,
      },
      success: ((log) => {
        const $buildContainer = $('.js-build-output');

        gl.utils.setCiStatusFavicon(`${this.pageUrl}/status.json`);

        if (log.state) {
          this.state = log.state;
        }

        if (log.append) {
          $buildContainer.append(log.html);
        } else {
          $buildContainer.html(log.html);
          if (log.truncated) {
            $('.js-truncated-info-size').html(` ${log.size} `);
            this.$truncatedInfo.removeClass('hidden');
            this.initAffixTruncatedInfo();
          } else {
            this.$truncatedInfo.addClass('hidden');
          }
        }

        this.checkAutoscroll();

        if (!log.complete) {
          Build.timeout = setTimeout(() => {
            this.invokeBuildTrace();
          }, 4000);
        } else {
          this.$buildRefreshAnimation.remove();
        }

        if (log.status !== this.buildStatus) {
          let pageUrl = this.pageUrl;

          if (this.$autoScrollStatus.data('state') === 'enabled') {
            pageUrl += DOWN_BUILD_TRACE;
          }

          gl.utils.visitUrl(pageUrl);
        }
      }),
      error: () => {
        this.$buildRefreshAnimation.remove();
        return this.initScrollMonitor();
      },
    });
  };

  Build.prototype.checkAutoscroll = function () {
    if (this.$autoScrollStatus.data('state') === 'enabled') {
      return $('html,body').scrollTop(this.$buildTrace.height());
    }

    // Handle a situation where user started new build
    // but never scrolled a page
    if (!this.$scrollTopBtn.is(':visible') &&
        !this.$scrollBottomBtn.is(':visible') &&
        !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
      this.$scrollBottomBtn.show();
    }
  };

  Build.prototype.initScrollButtonAffix = function () {
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
  Build.prototype.initScrollMonitor = function () {
    if (!gl.utils.isInViewport(this.$upBuildTrace.get(0)) &&
      !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
      // User is somewhere in middle of Build Log

      this.$scrollTopBtn.show();

      if (this.buildStatus === 'success' || this.buildStatus === 'failed') { // Check if Build is completed
        this.$scrollBottomBtn.show();
      } else if (this.$buildRefreshAnimation.is(':visible') &&
        !gl.utils.isInViewport(this.$buildRefreshAnimation.get(0))) {
        this.$scrollBottomBtn.show();
      } else {
        this.$scrollBottomBtn.hide();
      }

      // Hide Autoscroll Status Indicator
      if (this.$scrollBottomBtn.is(':visible')) {
        this.$autoScrollContainer.hide();
        this.$autoScrollStatusText.removeClass('animate');
      } else {
        this.$autoScrollContainer.css({
          top: this.$body.outerHeight() - AUTO_SCROLL_OFFSET,
        }).show();
        this.$autoScrollStatusText.addClass('animate');
      }
    } else if (gl.utils.isInViewport(this.$upBuildTrace.get(0)) &&
      !gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
      // User is at Top of Build Log

      this.$scrollTopBtn.hide();
      this.$scrollBottomBtn.show();

      this.$autoScrollContainer.hide();
      this.$autoScrollStatusText.removeClass('animate');
    } else if ((!gl.utils.isInViewport(this.$upBuildTrace.get(0)) &&
      gl.utils.isInViewport(this.$downBuildTrace.get(0))) ||
      (this.$buildRefreshAnimation.is(':visible') &&
      gl.utils.isInViewport(this.$buildRefreshAnimation.get(0)))) {
      // User is at Bottom of Build Log

      this.$scrollTopBtn.show();
      this.$scrollBottomBtn.hide();

      // Show and Reposition Autoscroll Status Indicator
      this.$autoScrollContainer.css({
        top: this.$body.outerHeight() - AUTO_SCROLL_OFFSET,
      }).show();
      this.$autoScrollStatusText.addClass('animate');
    } else if (gl.utils.isInViewport(this.$upBuildTrace.get(0)) &&
      gl.utils.isInViewport(this.$downBuildTrace.get(0))) {
      // Build Log height is small

      this.$scrollTopBtn.hide();
      this.$scrollBottomBtn.hide();

      // Hide Autoscroll Status Indicator
      this.$autoScrollContainer.hide();
      this.$autoScrollStatusText.removeClass('animate');
    }

    if (this.buildStatus === 'running' || this.buildStatus === 'pending') {
      // Check if Refresh Animation is in Viewport and enable Autoscroll, disable otherwise.
      this.$autoScrollStatus.data(
        'state',
        gl.utils.isInViewport(this.$buildRefreshAnimation.get(0)) ? 'enabled' : 'disabled',
      );
    }
  };

  Build.prototype.shouldHideSidebarForViewport = function () {
    const bootstrapBreakpoint = this.bp.getBreakpointSize();
    return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
  };

  Build.prototype.toggleSidebar = function (shouldHide) {
    const shouldShow = typeof shouldHide === 'boolean' ? !shouldHide : undefined;

    this.$buildScroll.toggleClass('sidebar-expanded', shouldShow)
      .toggleClass('sidebar-collapsed', shouldHide);
    this.$truncatedInfo.toggleClass('sidebar-expanded', shouldShow)
      .toggleClass('sidebar-collapsed', shouldHide);
    this.$sidebar.toggleClass('right-sidebar-expanded', shouldShow)
      .toggleClass('right-sidebar-collapsed', shouldHide);
  };

  Build.prototype.sidebarOnResize = function () {
    this.toggleSidebar(this.shouldHideSidebarForViewport());
  };

  Build.prototype.sidebarOnClick = function () {
    if (this.shouldHideSidebarForViewport()) this.toggleSidebar();
  };

  Build.prototype.updateArtifactRemoveDate = function () {
    const $date = $('.js-artifacts-remove');
    if ($date.length) {
      const date = $date.text();
      return $date.text(
        gl.utils.timeFor(new Date(date.replace(/([0-9]+)-([0-9]+)-([0-9]+)/g, '$1/$2/$3')), ' '),
      );
    }
  };

  Build.prototype.populateJobs = function (stage) {
    $('.build-job').hide();
    $(`.build-job[data-stage="${stage}"]`).show();
  };

  Build.prototype.updateStageDropdownText = function (stage) {
    $('.stage-selection').text(stage);
  };

  Build.prototype.updateDropdown = function (e) {
    e.preventDefault();
    const stage = e.currentTarget.text;
    this.updateStageDropdownText(stage);
    this.populateJobs(stage);
  };

  Build.prototype.stepTrace = function (e) {
    e.preventDefault();

    const $currentTarget = $(e.currentTarget);
    $.scrollTo($currentTarget.attr('href'), {
      offset: 0,
    });
  };

  Build.prototype.initAffixTruncatedInfo = function () {
    const offsetTop = this.$buildTrace.offset().top;

    this.$truncatedInfo.affix({
      offset: {
        top: offsetTop,
      },
    });
  };

  return Build;
})();
