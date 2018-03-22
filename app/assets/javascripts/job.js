import $ from 'jquery';
import _ from 'underscore';
import axios from './lib/utils/axios_utils';
import { visitUrl } from './lib/utils/url_utility';
import bp from './breakpoints';
import { numberToHumanSize } from './lib/utils/number_utils';
import { setCiStatusFavicon } from './lib/utils/common_utils';

export default class Job {
  constructor(options) {
    this.timeout = null;
    this.state = null;
    this.fetchingStatusFavicon = false;
    this.options = options || $('.js-build-options').data();

    this.pagePath = this.options.pagePath;
    this.buildStatus = this.options.buildStatus;
    this.state = this.options.logState;
    this.buildStage = this.options.buildStage;
    this.$document = $(document);
    this.$window = $(window);
    this.logBytes = 0;
    this.updateDropdown = this.updateDropdown.bind(this);

    this.$buildTrace = $('#build-trace');
    this.$buildRefreshAnimation = $('.js-build-refresh');
    this.$truncatedInfo = $('.js-truncated-info');
    this.$buildTraceOutput = $('.js-build-output');
    this.$topBar = $('.js-top-bar');

    // Scroll controllers
    this.$scrollTopBtn = $('.js-scroll-up');
    this.$scrollBottomBtn = $('.js-scroll-down');

    clearTimeout(this.timeout);

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

    this.$window
      .off('scroll')
      .on('scroll', () => {
        if (!this.isScrolledToBottom()) {
          this.toggleScrollAnimation(false);
        } else if (this.isScrolledToBottom() && !this.isLogComplete) {
          this.toggleScrollAnimation(true);
        }
        this.scrollThrottled();
      });

    this.$window
      .off('resize.build')
      .on('resize.build', _.throttle(this.sidebarOnResize.bind(this), 100));

    this.initAffixTopArea();

    this.getBuildTrace();
  }

  initAffixTopArea() {
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
  }

  // eslint-disable-next-line class-methods-use-this
  canScroll() {
    return $(document).height() > $(window).height();
  }

  toggleScroll() {
    const $document = $(document);
    const currentPosition = $document.scrollTop();
    const scrollHeight = $document.height();

    const windowHeight = $(window).height();
    if (this.canScroll()) {
      if (currentPosition > 0 &&
        (scrollHeight - currentPosition !== windowHeight)) {
      // User is in the middle of the log

        this.toggleDisableButton(this.$scrollTopBtn, false);
        this.toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (currentPosition === 0) {
        // User is at Top of  Log

        this.toggleDisableButton(this.$scrollTopBtn, true);
        this.toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (this.isScrolledToBottom()) {
        // User is at the bottom of the build log.

        this.toggleDisableButton(this.$scrollTopBtn, false);
        this.toggleDisableButton(this.$scrollBottomBtn, true);
      }
    } else {
      this.toggleDisableButton(this.$scrollTopBtn, true);
      this.toggleDisableButton(this.$scrollBottomBtn, true);
    }
  }
  // eslint-disable-next-line class-methods-use-this
  isScrolledToBottom() {
    const $document = $(document);

    const currentPosition = $document.scrollTop();
    const scrollHeight = $document.height();

    const windowHeight = $(window).height();

    return scrollHeight - currentPosition === windowHeight;
  }

  // eslint-disable-next-line class-methods-use-this
  scrollDown() {
    const $document = $(document);
    $document.scrollTop($document.height());
  }

  scrollToBottom() {
    this.scrollDown();
    this.hasBeenScrolled = true;
    this.toggleScroll();
  }

  scrollToTop() {
    $(document).scrollTop(0);
    this.hasBeenScrolled = true;
    this.toggleScroll();
  }

  // eslint-disable-next-line class-methods-use-this
  toggleDisableButton($button, disable) {
    if (disable && $button.prop('disabled')) return;
    $button.prop('disabled', disable);
  }

  toggleScrollAnimation(toggle) {
    this.$scrollBottomBtn.toggleClass('animate', toggle);
  }

  initSidebar() {
    this.$sidebar = $('.js-build-sidebar');
  }

  getBuildTrace() {
    return axios.get(`${this.pagePath}/trace.json`, {
      params: { state: this.state },
    })
      .then((res) => {
        const log = res.data;

        if (!this.fetchingStatusFavicon) {
          this.fetchingStatusFavicon = true;

          setCiStatusFavicon(`${this.pagePath}/status.json`)
            .then(() => {
              this.fetchingStatusFavicon = false;
            })
            .catch(() => {
              this.fetchingStatusFavicon = false;
            });
        }

        if (log.state) {
          this.state = log.state;
        }

        this.isScrollInBottom = this.isScrolledToBottom();

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
          const size = numberToHumanSize(this.logBytes);
          $('.js-truncated-info-size').html(`${size}`);
          this.$truncatedInfo.removeClass('hidden');
        } else {
          this.$truncatedInfo.addClass('hidden');
        }
        this.isLogComplete = log.complete;

        if (log.complete === false) {
          this.timeout = setTimeout(() => {
            this.getBuildTrace();
          }, 4000);
        } else {
          this.$buildRefreshAnimation.remove();
          this.toggleScrollAnimation(false);
        }

        if (log.status !== this.buildStatus) {
          visitUrl(this.pagePath);
        }
      })
      .catch(() => {
        this.$buildRefreshAnimation.remove();
      })
      .then(() => {
        if (this.isScrollInBottom) {
          this.scrollDown();
        }
      })
      .then(() => this.toggleScroll());
  }
  // eslint-disable-next-line class-methods-use-this
  shouldHideSidebarForViewport() {
    const bootstrapBreakpoint = bp.getBreakpointSize();
    return bootstrapBreakpoint === 'xs' || bootstrapBreakpoint === 'sm';
  }

  toggleSidebar(shouldHide) {
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
  }

  sidebarOnResize() {
    this.toggleSidebar(this.shouldHideSidebarForViewport());
  }

  sidebarOnClick() {
    if (this.shouldHideSidebarForViewport()) this.toggleSidebar();
  }

  // eslint-disable-next-line class-methods-use-this
  populateJobs(stage) {
    $('.build-job').hide();
    $(`.build-job[data-stage="${stage}"]`).show();
  }
  // eslint-disable-next-line class-methods-use-this
  updateStageDropdownText(stage) {
    $('.stage-selection').text(stage);
  }

  updateDropdown(e) {
    e.preventDefault();
    const stage = e.currentTarget.text;
    this.updateStageDropdownText(stage);
    this.populateJobs(stage);
  }
}
