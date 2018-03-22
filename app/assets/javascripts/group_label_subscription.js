import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import flash from './flash';
import { __ } from './locale';

export default class GroupLabelSubscription {
  constructor(container) {
    const $container = $(container);
    this.$dropdown = $container.find('.dropdown');
    this.$subscribeButtons = $container.find('.js-subscribe-button');
    this.$unsubscribeButtons = $container.find('.js-unsubscribe-button');

    this.$subscribeButtons.on('click', this.subscribe.bind(this));
    this.$unsubscribeButtons.on('click', this.unsubscribe.bind(this));
  }

  unsubscribe(event) {
    event.preventDefault();

    const url = this.$unsubscribeButtons.attr('data-url');
    axios.post(url)
      .then(() => {
        this.toggleSubscriptionButtons();
        this.$unsubscribeButtons.removeAttr('data-url');
      })
      .catch(() => flash(__('There was an error when unsubscribing from this label.')));
  }

  subscribe(event) {
    event.preventDefault();

    const $btn = $(event.currentTarget);
    const url = $btn.attr('data-url');

    this.$unsubscribeButtons.attr('data-url', url);

    axios.post(url)
      .then(() => this.toggleSubscriptionButtons())
      .catch(() => flash(__('There was an error when subscribing to this label.')));
  }

  toggleSubscriptionButtons() {
    this.$dropdown.toggleClass('hidden');
    this.$subscribeButtons.toggleClass('hidden');
    this.$unsubscribeButtons.toggleClass('hidden');
  }
}
