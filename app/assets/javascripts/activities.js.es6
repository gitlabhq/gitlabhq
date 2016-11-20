/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-undef, quotes, no-var, padded-blocks, max-len */
(function() {
  this.Activities = (function() {
    function Activities() {
      Pager.init(20, true, false, this.updateTooltips);
      $(".event-filter-link").on("click", (function(_this) {
        return function(event) {
          event.preventDefault();
          _this.toggleFilter($(event.currentTarget));
          return _this.reloadActivities();
        };
      })(this));
    }

    Activities.prototype.updateTooltips = function() {
      gl.utils.localTimeAgo($('.js-timeago', '.content_list'));
    };

    Activities.prototype.reloadActivities = function() {
      $(".content_list").html('');
      Pager.init(20, true, false, this.updateTooltips);
    };

    Activities.prototype.toggleFilter = function(sender) {
      var filter = sender.attr("id").split("_")[0];

      $('.event-filter .active').removeClass("active");
      Cookies.set("event_filter", filter);

      sender.closest('li').toggleClass("active");
    };

    return Activities;

  })();

}).call(this);
