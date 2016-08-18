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
      return gl.utils.localTimeAgo($('.js-timeago', '.content_list'));
    };

    Activities.prototype.reloadActivities = function() {
      $(".content_list").html('');
      return Pager.init(20, true);
    };

    Activities.prototype.toggleFilter = function(sender) {
      var event_filters, filter;
      $('.event-filter .active').removeClass("active");
      event_filters = $.cookie("event_filter");
      filter = sender.attr("id").split("_")[0];
      $.cookie("event_filter", (event_filters !== filter ? filter : ""), {
        path: gon.relative_url_root || '/'
      });
      if (event_filters !== filter) {
        return sender.closest('li').toggleClass("active");
      }
    };

    return Activities;

  })();

}).call(this);
