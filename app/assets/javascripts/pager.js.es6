(() => {
  const Pager = {
    init(limit = 0, preload = false, disable = false, callback = $.noop) {
      this.limit = limit;
      this.disable = disable;
      this.callback = callback;
      this.loading = $('.loading').first();
      if (preload) {
        this.offset = 0;
        this.getOld();
      } else {
        this.offset = this.limit;
      }
      this.initLoadMore();
    },

    getOld() {
      this.loading.show();
      $.ajax({
        type: 'GET',
        url: $('.content_list').data('href') || window.location.href,
        data: `limit=${this.limit}&offset=${this.offset}`,
        complete: () => this.loading.hide(),
        success: (data) => {
          Pager.append(data.count, data.html);
          Pager.callback();
        },
        dataType: 'json',
      });
    },

    append(count, html) {
      $('.content_list').append(html);
      if (count > 0) {
        this.offset += count;
      } else {
        this.disable = true;
      }
    },

    initLoadMore() {
      $(document).unbind('scroll');
      $(document).endlessScroll({
        bottomPixels: 400,
        fireDelay: 1000,
        fireOnce: true,
        ceaseFire: () => Pager.disable !== true,
        callback: () => {
          if (!this.loading.is(':visible')) {
            this.loading.show();
            Pager.getOld();
          }
        },
      });
    },
  };

  window.Pager = Pager;
})();
