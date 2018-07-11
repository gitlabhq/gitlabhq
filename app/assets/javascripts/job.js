import $ from 'jquery';
import _ from 'underscore';
import { polyfillSticky } from './lib/utils/sticky';
import axios from './lib/utils/axios_utils';
import { visitUrl } from './lib/utils/url_utility';
import bp from './breakpoints';
import { numberToHumanSize } from './lib/utils/number_utils';
import { setCiStatusFavicon } from './lib/utils/common_utils';
import { isScrolledToBottom, scrollDown } from './lib/utils/scroll_utils';
import LogOutputBehaviours from './lib/utils/logoutput_behaviours';

export default class Job extends LogOutputBehaviours {
  constructor(options) {
    super();
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

    this.scrollThrottled = _.throttle(this.toggleScroll.bind(this), 100);

    this.$window
      .off('scroll')
      .on('scroll', () => {
        if (!isScrolledToBottom()) {
          this.toggleScrollAnimation(false);
        } else if (isScrolledToBottom() && !this.isLogComplete) {
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
    polyfillSticky(this.$topBar);
  }

  scrollToBottom() {
    scrollDown();
    this.hasBeenScrolled = true;
    this.toggleScroll();
  }

  scrollToTop() {
    $(document).scrollTop(0);
    this.hasBeenScrolled = true;
    this.toggleScroll();
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

        this.isScrollInBottom = isScrolledToBottom();

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
          scrollDown();
        }
      })
      .then(() => this.toggleScroll());
  }
  // eslint-disable-next-line class-methods-use-this
  shouldHideSidebarForViewport() {
    const bootstrapBreakpoint = bp.getBreakpointSize();
    return bootstrapBreakpoint === 'xs';
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
