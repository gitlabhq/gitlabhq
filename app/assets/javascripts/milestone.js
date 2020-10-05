import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import { deprecatedCreateFlash as flash } from './flash';
import { mouseenter, debouncedMouseleave, togglePopover } from './shared/popover';
import { __ } from './locale';

export default class Milestone {
  constructor() {
    this.bindTabsSwitching();
    this.loadInitialTab();
  }

  bindTabsSwitching() {
    return $('a[data-toggle="tab"]').on('show.bs.tab', e => {
      const $target = $(e.target);

      window.location.hash = $target.attr('href');
      this.loadTab($target);
    });
  }

  loadInitialTab() {
    const $target = $(`.js-milestone-tabs a:not(.active)[href="${window.location.hash}"]`);

    if ($target.length) {
      $target.tab('show');
    } else {
      this.loadTab($('.js-milestone-tabs a.active'));
    }
  }
  // eslint-disable-next-line class-methods-use-this
  loadTab($target) {
    const endpoint = $target.data('endpoint');
    const tabElId = $target.attr('href');

    if (endpoint && !$target.hasClass('is-loaded')) {
      axios
        .get(endpoint)
        .then(({ data }) => {
          $(tabElId).html(data.html);
          $target.addClass('is-loaded');
        })
        .catch(() => flash(__('Error loading milestone tab')));
    }
  }

  static initDeprecationMessage() {
    const deprecationMesssageContainer = document.querySelector(
      '.js-milestone-deprecation-message',
    );

    if (!deprecationMesssageContainer) return;

    const deprecationMessage = deprecationMesssageContainer.querySelector(
      '.js-milestone-deprecation-message-template',
    ).innerHTML;
    const $popover = $('.js-popover-link', deprecationMesssageContainer);
    const hideOnScroll = togglePopover.bind($popover, false);

    $popover
      .popover({
        content: deprecationMessage,
        html: true,
        placement: 'bottom',
      })
      .on('mouseenter', mouseenter)
      .on('mouseleave', debouncedMouseleave())
      .on('show.bs.popover', () => {
        window.addEventListener('scroll', hideOnScroll, { once: true });
      });
  }
}
