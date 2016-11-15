/* eslint-disable */
(function(global) {
  class LabelSubscription {
    constructor(container) {
      $(container).on('click', '.js-subscribe-button', this.toggleSubscription);
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

        $span.text(newAction);
        $span.toggleClass('hidden');
        $btn.removeClass('disabled');
        $btn.tooltip('hide').attr('data-original-title', newAction).tooltip('fixTitle');
        $btn.attr('data-status', newStatus);
      });
    }
  }

  global.LabelSubscription = LabelSubscription;

})(window.gl || (window.gl = {}));
