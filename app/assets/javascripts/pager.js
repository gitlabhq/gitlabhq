import $ from 'jquery';
import 'vendor/jquery.endless-scroll';
import axios from '~/lib/utils/axios_utils';
import { removeParams, getParameterByName } from '~/lib/utils/url_utility';

const ENDLESS_SCROLL_BOTTOM_PX = 400;
const ENDLESS_SCROLL_FIRE_DELAY_MS = 1000;

export default {
  init({
    limit = 0,
    preload = false,
    disable = false,
    prepareData = $.noop,
    successCallback = $.noop,
    errorCallback = $.noop,
    container = '',
  } = {}) {
    this.limit = limit;
    this.offset = parseInt(getParameterByName('offset'), 10) || this.limit;
    this.disable = disable;
    this.prepareData = prepareData;
    this.successCallback = successCallback;
    this.errorCallback = errorCallback;
    this.loading = $(`${container} .loading`).first();
    if (preload) {
      this.offset = 0;
      this.getOld();
    }
    this.initLoadMore();
  },

  getOld() {
    this.loading.show();
    const url = $('.content_list').data('href') || removeParams(['limit', 'offset']);

    axios
      .get(url, {
        params: {
          limit: this.limit,
          offset: this.offset,
        },
      })
      .then(({ data }) => {
        this.append(data.count, this.prepareData(data.html));
        this.successCallback();

        // keep loading until we've filled the viewport height
        if (!this.disable && !this.isScrollable()) {
          this.getOld();
        } else {
          this.loading.hide();
        }
      })
      .catch((err) => this.errorCallback(err))
      .finally(() => this.loading.hide());
  },

  append(count, html) {
    $('.content_list').append(html);
    if (count > 0) {
      this.offset += count;

      if (count < this.limit) {
        this.disable = true;
      }
    } else {
      this.disable = true;
    }
  },

  isScrollable() {
    const $w = $(window);
    return $(document).height() > $w.height() + $w.scrollTop() + ENDLESS_SCROLL_BOTTOM_PX;
  },

  initLoadMore() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    $(document).off('scroll');
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
