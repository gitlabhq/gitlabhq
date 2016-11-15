/* eslint-disable */
(function(global) {
  class GroupLabelSubscription {
    constructor(container) {
      const $container = $(container);
      this.$dropdown = $container.find('.dropdown');
      this.$unsubscribeBtn = $container.find('.js-unsubscribe-button');

      $container.on('click', '.js-subscribe-button', this.subscribe.bind(this));
      $container.on('click', '.js-unsubscribe-button', this.unsubscribe.bind(this));
    }

    unsubscribe(event) {
      event.preventDefault();

      const url = this.$unsubscribeBtn.attr('data-url');

      $.ajax({
        type: 'POST',
        url: url
      }).done(() => {
        this.$dropdown.toggleClass('hidden');
        this.$unsubscribeBtn.toggleClass('hidden');
        this.$unsubscribeBtn.removeAttr('data-url');
      });
    }

    subscribe(event) {
      event.preventDefault();

      const $btn = $(event.currentTarget);
      const url = $btn.attr('data-url');

      this.$unsubscribeBtn.attr('data-url', url);

      $.ajax({
        type: 'POST',
        url: url
      }).done(() => {
        this.$dropdown.toggleClass('hidden');
        this.$unsubscribeBtn.toggleClass('hidden');
      });
    }
  }

  global.GroupLabelSubscription = GroupLabelSubscription;

})(window.gl || (window.gl = {}));
