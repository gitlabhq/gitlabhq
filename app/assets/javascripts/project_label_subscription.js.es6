/* eslint-disable */
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

        for (let button of this.$buttons) {
          let $button = $(button);

          if ($button.attr('data-original-title')) {
            $button.tooltip('hide').attr('data-original-title', newAction).tooltip('fixTitle');
          }
        }
      });
    }
  }

  global.ProjectLabelSubscription = ProjectLabelSubscription;

})(window.gl || (window.gl = {}));
