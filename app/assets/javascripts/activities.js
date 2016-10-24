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
      var filter = sender.attr("id").split("_")[0];

      $('.event-filter .active').removeClass("active");
      Cookies.set("event_filter", filter, {
        path: gon.relative_url_root || '/'
      });

      sender.closest('li').toggleClass("active");
    };

    return Activities;

  })();

}).call(this);
