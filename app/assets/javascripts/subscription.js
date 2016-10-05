(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Subscription = (function() {
    function Subscription(container) {
      this.toggleSubscription = bind(this.toggleSubscription, this);
      var $container;
      $container = $(container);
      this.url = $container.attr('data-url');
      this.subscribe_button = $container.find('.js-subscribe-button');
      this.subscription_status = $container.find('.subscription-status');
      this.subscribe_button.unbind('click').click(this.toggleSubscription);
    }

    Subscription.prototype.toggleSubscription = function(event) {
      var action, btn, current_status;
      btn = $(event.currentTarget);
      action = btn.find('span').text();
      current_status = this.subscription_status.attr('data-status');
      btn.addClass('disabled');
      return $.post(this.url, (function(_this) {
        return function() {
          var status;
          btn.removeClass('disabled');

          if ($('body').data('page') === 'projects:boards:show') {
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
