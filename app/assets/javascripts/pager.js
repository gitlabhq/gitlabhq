this.Pager = {
  init: function(limit, preload, disable, callback) {
    this.limit = limit != null ? limit : 0;
    this.disable = disable != null ? disable : false;
    this.callback = callback != null ? callback : $.noop;
    this.loading = $('.loading').first();
    if (preload) {
      this.offset = 0;
      this.getOld();
    } else {
      this.offset = this.limit;
    }
    return this.initLoadMore();
  },
  getOld: function() {
    this.loading.show();
    return $.ajax({
      type: "GET",
      url: $(".content_list").data('href') || location.href,
      data: "limit=" + this.limit + "&offset=" + this.offset,
      complete: (function(_this) {
        return function() {
          return _this.loading.hide();
        };
      })(this),
      success: function(data) {
        Pager.append(data.count, data.html);
        return Pager.callback();
      },
      dataType: "json"
    });
  },
  append: function(count, html) {
    $(".content_list").append(html);
    if (count > 0) {
      return this.offset += count;
    } else {
      return this.disable = true;
    }
  },
  initLoadMore: function() {
    $(document).unbind('scroll');
    return $(document).endlessScroll({
      bottomPixels: 400,
      fireDelay: 1000,
      fireOnce: true,
      ceaseFire: function() {
        return Pager.disable;
      },
      callback: (function(_this) {
        return function(i) {
          if (!_this.loading.is(':visible')) {
            _this.loading.show();
            return Pager.getOld();
          }
        };
      })(this)
    });
  }
};
