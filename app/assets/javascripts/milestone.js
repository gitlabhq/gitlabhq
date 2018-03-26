import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import flash from './flash';
import { mouseenter, debouncedMouseleave } from './shared/popover';

export default class Milestone {
  constructor() {
    Milestone.initDeprecationMessage();
    this.bindTabsSwitching();

    // Load merge request tab if it is active
    // merge request tab is active based on different conditions in the backend
    this.loadTab($('.js-milestone-tabs .active a'));

    this.loadInitialTab();
  }

  bindTabsSwitching() {
    return $('a[data-toggle="tab"]').on('show.bs.tab', (e) => {
      const $target = $(e.target);

      location.hash = $target.attr('href');
      this.loadTab($target);
    });
  }
  // eslint-disable-next-line class-methods-use-this
  loadInitialTab() {
    const $target = $(`.js-milestone-tabs a[href="${location.hash}"]`);

    if ($target.length) {
      $target.tab('show');
    }
  }
  // eslint-disable-next-line class-methods-use-this
  loadTab($target) {
    const endpoint = $target.data('endpoint');
    const tabElId = $target.attr('href');

    if (endpoint && !$target.hasClass('is-loaded')) {
      axios.get(endpoint)
        .then(({ data }) => {
          $(tabElId).html(data.html);
          $target.addClass('is-loaded');
        })
        .catch(() => flash('Error loading milestone tab'));
    }
  }

  static initDeprecationMessage() {
    const deprecationMesssageContainer = document.querySelector('.milestone-deprecation-message');

    if (!deprecationMesssageContainer) return;

    const deprecationMessage = deprecationMesssageContainer.querySelector('.milestone-deprecation-message-template').innerHTML;
    const popoverLink = deprecationMesssageContainer.querySelector('.popover-link');

    $(popoverLink).popover({
      content: deprecationMessage,
      html: true,
      placement: 'bottom',
      trigger: 'manual',
    })
    .on('mouseenter', mouseenter)
    .on('mouseleave', debouncedMouseleave());
  }
}
