/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, vars-on-top, no-unused-vars, one-var, one-var-declaration-per-line, camelcase, consistent-return, no-undef, padded-blocks, max-len */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Subscription = (function() {
    function Subscription(container) {
      this.toggleSubscription = bind(this.toggleSubscription, this);
      var $container;
      this.$container = $(container);
      this.url = this.$container.attr('data-url');
      this.subscribe_button = this.$container.find('.js-subscribe-button');
      this.subscription_status = this.$container.find('.subscription-status');
      this.subscribe_button.unbind('click').click(this.toggleSubscription);
    }

    Subscription.prototype.toggleSubscription = function(event) {
      var action, btn, current_status;
      btn = $(event.currentTarget);
      action = btn.find('span').text();
      current_status = this.subscription_status.attr('data-status');
      btn.addClass('disabled');

      if ($('html').hasClass('issue-boards-page')) {
        this.url = this.$container.attr('data-url');
      }

      return $.post(this.url, (function(_this) {
        return function() {
          var status;
          btn.removeClass('disabled');

          if ($('html').hasClass('issue-boards-page')) {
            Vue.set(gl.issueBoards.BoardsStore.detail.issue, 'subscribed', !gl.issueBoards.BoardsStore.detail.issue.subscribed);
          } else {
            status = current_status === 'subscribed' ? 'unsubscribed' : 'subscribed';
            _this.subscription_status.attr('data-status', status);
            action = status === 'subscribed' ? 'Unsubscribe' : 'Subscribe';
            btn.find('span').text(action);
            _this.subscription_status.find('>div').toggleClass('hidden');
            if (btn.attr('data-original-title')) {
              return btn.tooltip('hide').attr('data-original-title', action).tooltip('fixTitle');
            }
          }
        };
      })(this));
    };

    return Subscription;

  })();

}).call(this);
