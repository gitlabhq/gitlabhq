import $ from 'jquery';
import { fixTitle } from '~/tooltips';
import createFlash from './flash';
import axios from './lib/utils/axios_utils';
import { __ } from './locale';

const tooltipTitles = {
  group: {
    subscribed: __('Unsubscribe at group level'),
    unsubscribed: __('Subscribe at group level'),
  },
  project: {
    subscribed: __('Unsubscribe at project level'),
    unsubscribed: __('Subscribe at project level'),
  },
};

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

    axios
      .post(url)
      .then(() => {
        let newStatus;
        let newAction;

        if (oldStatus === 'unsubscribed') {
          [newStatus, newAction] = ['subscribed', __('Unsubscribe')];
        } else {
          [newStatus, newAction] = ['unsubscribed', __('Subscribe')];
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
      })
      .catch(() =>
        createFlash({
          message: __('There was an error subscribing to this label.'),
        }),
      );
  }

  static setNewTitle($button, originalTitle, newStatus) {
    const type = /group/.test(originalTitle) ? 'group' : 'project';
    const newTitle = tooltipTitles[type][newStatus];

    $button.attr('title', newTitle);
    fixTitle($button);
  }
}
