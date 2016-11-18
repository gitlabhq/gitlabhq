/* eslint-disable */
(function(global) {
  class GroupLabelSubscription {
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

      $.ajax({
        type: 'POST',
        url: url
      }).done(() => {
        this.toggleSubscriptionButtons();
        this.$unsubscribeButtons.removeAttr('data-url');
      });
    }

    subscribe(event) {
      event.preventDefault();

      const $btn = $(event.currentTarget);
      const url = $btn.attr('data-url');

      this.$unsubscribeButtons.attr('data-url', url);

      $.ajax({
        type: 'POST',
        url: url
      }).done(() => {
        this.toggleSubscriptionButtons();
      });
    }

    toggleSubscriptionButtons() {
      this.$dropdown.toggleClass('hidden');
      this.$subscribeButtons.toggleClass('hidden');
      this.$unsubscribeButtons.toggleClass('hidden');
    }
  }

  global.GroupLabelSubscription = GroupLabelSubscription;

})(window.gl || (window.gl = {}));
