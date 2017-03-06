/* eslint-disable wrap-iife, func-names, space-before-function-paren, object-shorthand, comma-dangle, one-var, one-var-declaration-per-line, no-restricted-syntax, max-len, no-param-reassign */

(function(global) {
  class ProjectLabelSubscription {
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

      $.ajax({
        type: 'POST',
        url: url
      }).done(() => {
        let newStatus, newAction;

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
      });
    }
  }

  global.ProjectLabelSubscription = ProjectLabelSubscription;
})(window.gl || (window.gl = {}));
