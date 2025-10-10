import $ from 'jquery';
import { setupEndlessScroll } from 'vendor/jquery.endless-scroll';
import axios from '~/lib/utils/axios_utils';
import { removeParams, getParameterByName } from '~/lib/utils/url_utility';

setupEndlessScroll($);

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
    this.$container = $(container);
    this.$loading = this.$container.length
      ? this.$container.find('.loading').first()
      : $('.loading').first();
    if (preload) {
      this.offset = 0;
      this.getOld();
    }
    if (this.isProjectStudioUI()) {
      this.initLoadMoreForProjectStudio();
    } else {
      this.initLoadMore();
    }
  },

  isProjectStudioUI() {
    return gon.features.projectStudioEnabled;
  },

  getOld() {
    this.$loading.show();
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

        const isProjectStudio = this.isProjectStudioUI();

        // Re-observe for paneled view after content is loaded
        if (isProjectStudio && !this.disable) {
          const loadingEl = this.$loading.get(0);
          if (loadingEl && this.isScrollable()) {
            this.loadingObserver.observe(loadingEl);
          }
        }

        if (!isProjectStudio) {
          // keep loading until we've filled the viewport height
          if (!this.disable && !this.isScrollable()) {
            this.getOld();
          } else {
            this.$loading.hide();
          }
        }
      })
      .catch((err) => this.errorCallback(err))
      .finally(() => {
        if (!this.isProjectStudioUI() || this.disable) {
          this.$loading.hide();
        }
      });
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
    if (this.isProjectStudioUI()) {
      const container = document.querySelector('.js-static-panel-inner');
      if (container) {
        return container.scrollHeight > container.clientHeight + container.scrollTop;
      }
      return false;
    }

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
        if (this.$container.length && !this.$container.is(':visible')) {
          return;
        }

        if (!this.$loading.is(':visible')) {
          this.$loading.show();
          this.getOld();
        }
      },
    });
  },

  initLoadMoreForProjectStudio() {
    const loadingEl = this.$loading.get(0);
    if (loadingEl) {
      if (this.loadingObserver) this.loadingObserver.disconnect();
      this.loadingObserver = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              this.loadingObserver.unobserve(loadingEl);

              this.getOld();
            }
          });
        },
        {
          root: document.querySelector('.js-static-panel-inner'),
          threshold: 1,
        },
      );

      // Show the loading spinner initially for observer to work
      if (this.isScrollable()) {
        this.$loading.show();
        this.loadingObserver.observe(loadingEl);
      }
    }
  },
};
