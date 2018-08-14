import $ from 'jquery';
import { canScroll, isScrolledToBottom, toggleDisableButton } from './scroll_utils';

export default class LogOutputBehaviours {
  constructor() {
    // Scroll buttons
    this.$scrollTopBtn = $('.js-scroll-up');
    this.$scrollBottomBtn = $('.js-scroll-down');

    this.$scrollTopBtn.off('click').on('click', this.scrollToTop.bind(this));
    this.$scrollBottomBtn.off('click').on('click', this.scrollToBottom.bind(this));
  }

  toggleScroll() {
    const $document = $(document);
    const currentPosition = $document.scrollTop();
    const scrollHeight = $document.height();

    const windowHeight = $(window).height();
    if (canScroll()) {
      if (currentPosition > 0 && scrollHeight - currentPosition !== windowHeight) {
        // User is in the middle of the log

        toggleDisableButton(this.$scrollTopBtn, false);
        toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (currentPosition === 0) {
        // User is at Top of  Log

        toggleDisableButton(this.$scrollTopBtn, true);
        toggleDisableButton(this.$scrollBottomBtn, false);
      } else if (isScrolledToBottom()) {
        // User is at the bottom of the build log.

        toggleDisableButton(this.$scrollTopBtn, false);
        toggleDisableButton(this.$scrollBottomBtn, true);
      }
    } else {
      toggleDisableButton(this.$scrollTopBtn, true);
      toggleDisableButton(this.$scrollBottomBtn, true);
    }
  }

  toggleScrollAnimation(toggle) {
    this.$scrollBottomBtn.toggleClass('animate', toggle);
  }
}
