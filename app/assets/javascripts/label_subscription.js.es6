/* eslint-disable */
(function(global) {
  class LabelSubscription {
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
      const status = $btn.attr('data-status');

      $btn.addClass('disabled');
      $span.toggleClass('hidden');

      $.ajax({
        type: 'POST',
        url: url
      }).done(() => {
        let newStatus, newAction;

        if (status === 'subscribed') {
          [newStatus, newAction] = ['unsubscribed', 'Subscribe'];
        } else {
          [newStatus, newAction] = ['subscribed', 'Unsubscribe'];
        }

        $span.toggleClass('hidden');
        $btn.removeClass('disabled');

        this.$buttons.attr('data-status', newStatus);
        this.$buttons.find('> span').text(newAction);

        for (let button of this.$buttons) {
          let $button = $(button);

          if ($button.attr('data-original-title')) {
            $button.tooltip('hide').attr('data-original-title', newAction).tooltip('fixTitle');
          }
        }
      });
    }
  }

  global.LabelSubscription = LabelSubscription;

})(window.gl || (window.gl = {}));
