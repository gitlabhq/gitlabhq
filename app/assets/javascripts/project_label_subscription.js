import $ from 'jquery';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import flash from './flash';

export default class ProjectLabelSubscription {
  constructor(container) {
    this.$container = $(container);
    this.$buttons = this.$container.find('.js-subscribe-button');

    this.$buttons.on('click', this.toggleSubscription.bind(this));
  }

  toggleSubscription(event) {
    event.preventDefault();

    const $btn = $(event.currentTarget);
    const $span = $btn.find('span');
    const url = $btn.attr('data-url');
    const oldStatus = $btn.attr('data-status');

    $btn.addClass('disabled');
    $span.toggleClass('hidden');

    axios.post(url).then(() => {
      let newStatus;
      let newAction;

      if (oldStatus === 'unsubscribed') {
        [newStatus, newAction] = ['subscribed', 'Unsubscribe'];
      } else {
        [newStatus, newAction] = ['unsubscribed', 'Subscribe'];
      }

      $span.toggleClass('hidden');
      $btn.removeClass('disabled');

      this.$buttons.attr('data-status', newStatus);
      this.$buttons.find('> span').text(newAction);

      this.$buttons.map((button) => {
        const $button = $(button);

        if ($button.attr('data-original-title')) {
          $button.tooltip('hide').attr('data-original-title', newAction).tooltip('fixTitle');
        }

        return button;
      });
    }).catch(() => flash(__('There was an error subscribing to this label.')));
  }
}
