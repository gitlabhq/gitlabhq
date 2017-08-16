/* eslint-disable func-names, wrap-iife, no-use-before-define,
consistent-return, prefer-rest-params */
import _ from 'underscore';
import bp from './breakpoints';
import { bytesToKiB } from './lib/utils/number_utils';

window.Build = (function () {
  Build.timeout = null;
  Build.state = null;

  function Build(options) {
    this.options = options || $('.js-build-options').data();

    this.pageUrl = this.options.pageUrl;
    this.buildStatus = this.options.buildStatus;
    this.state = this.options.logState;
    this.buildStage = this.options.buildStage;
    this.$document = $(document);
    this.logBytes = 0;
    this.hasBeenScrolled = false;

    this.updateDropdown = this.updateDropdown.bind(this);
    this.getBuildTrace = this.getBuildTrace.bind(this);

    this.$buildTrace = $('#build-trace');
    this.$buildRefreshAnimation = $('.js-build-refresh');
    this.$truncatedInfo = $('.js-truncated-info');
    this.$buildTraceOutput = $('.js-build-output');
    this.$topBar = $('.js-top-bar');

    // Scroll controllers
    this.$scrollTopBtn = $('.js-scroll-up');
    this.$scrollBottomBtn = $('.js-scroll-down');

    clearTimeout(Build.timeout);

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

    // add event listeners to the scroll buttons
    this.$scrollTopBtn
      .off('click')
      .on('click', this.scrollToTop.bind(this));

    this.$scrollBottomBtn
      .off('click')
      .on('click', this.scrollToBottom.bind(this));

    this.scrollThrottled = _.throttle(this.toggleScroll.bind(this), 100);

    $(window)
      .off('scroll')
      .on('scroll', () => {
        const contentHeight = this.$buildTraceOutput.height();
        if (contentHeight > this.windowSize) {
          // means the user did not scroll, the content was updated.
          this.windowSize = contentHeight;
        } else {
          // User scrolled
          this.hasBeenScrolled = true;
          this.toggleScrollAnimation(false);
        }

        this.scrollThrottled();
      });

    $(window)
      .off('resize.build')
      .on('resize.build', _.throttle(this.sidebarOnResize.bind(this), 100));

    this.updateArtifactRemoveDate();
    this.initAffixTopArea();

    this.getBuildTrace();
  }

  Build.prototype.initAffixTopArea = function () {
    /**
      If the browser does not support position sticky, it returns the position as static.
      If the browser does support sticky, then we allow the browser to handle it, if not
      then we default back to Bootstraps affix
    **/
    if (this.$topBar.css('position') !== 'static') return;

    const offsetTop = this.$buildTrace.offset().top;

    this.$topBar.affix({
      offset: {
        top: offsetTop,
      },
    });
  };

  Build.prototype.canScroll = function () {
    return $(document).height() > $(window).height();
  };

  Build.prototype.toggleScroll = function () {
    const currentPosition = $(document).scrollTop();
    const scrollHeight = $(document).height();

    const windowHeight = $(window).height();
    if (this.canScroll()) {
      if (currentPosition > 0 &&
        (scrollHeight - currentPosition !== windowHeight)) {
      // User is in the middle of the log

        this.toggleDisableButton(this.$scrollTopBtn, false);
        this.toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (currentPosition === 0) {
        // User is at Top of Build Log

        this.toggleDisableButton(this.$scrollTopBtn, true);
        this.toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (scrollHeight - currentPosition === windowHeight) {
        // User is at the bottom of the build log.

        this.toggleDisableButton(this.$scrollTopBtn, false);
        this.toggleDisableButton(this.$scrollBottomBtn, true);
      }
    } else {
      this.toggleDisableButton(this.$scrollTopBtn, true);
      this.toggleDisableButton(this.$scrollBottomBtn, true);
    }
  };

  Build.prototype.scrollDown = function () {
    $(document).scrollTop($(document).height());
  };

  Build.prototype.scrollToBottom = function () {
    this.scrollDown();
    this.hasBeenScrolled = true;
    this.toggleScroll();
  };

  Build.prototype.scrollToTop = function () {
    $(document).scrollTop(0);
    this.hasBeenScrolled = true;
    this.toggleScroll();
  };

  Build.prototype.toggleDisableButton = function ($button, disable) {
    if (disable && $button.prop('disabled')) return;
    $button.prop('disabled', disable);
  };

  Build.prototype.toggleScrollAnimation = function (toggle) {
    this.$scrollBottomBtn.toggleClass('animate', toggle);
  };

  Build.prototype.initSidebar = function () {
    this.$sidebar = $('.js-build-sidebar');
  };

  Build.prototype.getBuildTrace = function () {
    return $.ajax({
      url: `${this.pageUrl}/trace.json`,
      data: this.state,
    })
      .done((log) => {
        gl.utils.setCiStatusFavicon(`${this.pageUrl}/status.json`);

        if (log.state) {
          this.state = log.state;
        }

        this.windowSize = this.$buildTraceOutput.height();

        if (log.append) {
          this.$buildTraceOutput.append(log.html);
          this.logBytes += log.size;
        } else {
          this.$buildTraceOutput.html(log.html);
          this.logBytes = log.size;
        }

        // if the incremental sum of logBytes we received is less than the total
        // we need to show a message warning the user about that.
        if (this.logBytes < log.total) {
          // size is in bytes, we need to calculate KiB
          const size = bytesToKiB(this.logBytes);
          $('.js-truncated-info-size').html(`${size}`);
          this.$truncatedInfo.removeClass('hidden');
        } else {
          this.$truncatedInfo.addClass('hidden');
        }

        if (!log.complete) {
          if (!this.hasBeenScrolled) {
            this.toggleScrollAnimation(true);
          } else {
            this.toggleScrollAnimation(false);
          }

          Build.timeout = setTimeout(() => {
            this.getBuildTrace();
          }, 4000);
        } else {
          this.$buildRefreshAnimation.remove();
          this.toggleScrollAnimation(false);
        }

        if (log.status !== this.buildStatus) {
          gl.utils.visitUrl(this.pageUrl);
        }
      })
      .fail(() => {
        this.$buildRefreshAnimation.remove();
      })
      .then(() => {
        if (!this.hasBeenScrolled) {
          this.scrollDown();
        }
      })
      .then(() => this.toggleScroll());
  };

  Build.prototype.shouldHideSidebarForViewport = function () {
    const bootstrapBreakpoint = bp.getBreakpointSize();
    return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
  };

  Build.prototype.toggleSidebar = function (shouldHide) {
    const shouldShow = typeof shouldHide === 'boolean' ? !shouldHide : undefined;
    const $toggleButton = $('.js-sidebar-build-toggle-header');

    this.$sidebar
      .toggleClass('right-sidebar-expanded', shouldShow)
      .toggleClass('right-sidebar-collapsed', shouldHide);

    this.$topBar
      .toggleClass('sidebar-expanded', shouldShow)
      .toggleClass('sidebar-collapsed', shouldHide);

    if (this.$sidebar.hasClass('right-sidebar-expanded')) {
      $toggleButton.addClass('hidden');
    } else {
      $toggleButton.removeClass('hidden');
    }
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

  return Build;
})();
