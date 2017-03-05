(() => {
  const ENDLESS_SCROLL_BOTTOM_PX = 400;
  const ENDLESS_SCROLL_FIRE_DELAY_MS = 1000;

  const Pager = {
    init(limit = 0, preload = false, disable = false, callback = $.noop) {
      this.limit = limit;
      this.offset = this.limit;
      this.disable = disable;
      this.callback = callback;
      this.loading = $('.loading').first();
      if (preload) {
        this.offset = 0;
        this.getOld();
      }
      this.initLoadMore();
    },

    getOld() {
      this.loading.show();
      $.ajax({
        type: 'GET',
        url: $('.content_list').data('href') || window.location.href,
        data: `limit=${this.limit}&offset=${this.offset}`,
        dataType: 'json',
        error: () => this.loading.hide(),
        success: (data) => {
          this.append(data.count, data.html);
          this.callback();

          // keep loading until we've filled the viewport height
          if (!this.disable && !this.isScrollable()) {
            this.getOld();
          } else {
            this.loading.hide();
          }
        },
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

    isScrollable() {
      const $w = $(window);
      return $(document).height() > $w.height() + $w.scrollTop() + ENDLESS_SCROLL_BOTTOM_PX;
    },

    initLoadMore() {
      $(document).unbind('scroll');
      $(document).endlessScroll({
        bottomPixels: ENDLESS_SCROLL_BOTTOM_PX,
        fireDelay: ENDLESS_SCROLL_FIRE_DELAY_MS,
        fireOnce: true,
        ceaseFire: () => this.disable === true,
        callback: () => {
          if (!this.loading.is(':visible')) {
            this.loading.show();
            this.getOld();
          }
        },
      });
    },
  };

  window.Pager = Pager;
})();
