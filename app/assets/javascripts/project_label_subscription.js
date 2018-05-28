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
    const url = $btn.attr('data-url');
    const oldStatus = $btn.attr('data-status');

    $btn.addClass('disabled');

    axios.post(url).then(() => {
      let newStatus;
      let newAction;

      if (oldStatus === 'unsubscribed') {
        [newStatus, newAction] = ['subscribed', 'Unsubscribe'];
      } else {
        [newStatus, newAction] = ['unsubscribed', 'Subscribe'];
      }

      $btn.removeClass('disabled');

      this.$buttons.attr('data-status', newStatus);
      this.$buttons.find('> span').text(newAction);

      this.$buttons.map((i, button) => {
        const $button = $(button);
        const originalTitle = $button.attr('data-original-title');

        if (originalTitle) {
          ProjectLabelSubscription.setNewTitle($button, originalTitle, newStatus, newAction);
        }

        return button;
      });
    }).catch(() => flash(__('There was an error subscribing to this label.')));
  }

  static setNewTitle($button, originalTitle, newStatus, newAction) {
    const newStatusVerb = newStatus.slice(0, -1);
    const actionRegexp = new RegExp(newStatusVerb, 'i');
    const newTitle = originalTitle.replace(actionRegexp, newAction);

    $button.tooltip('hide').attr('data-original-title', newTitle).tooltip('_fixTitle');
  }
}
