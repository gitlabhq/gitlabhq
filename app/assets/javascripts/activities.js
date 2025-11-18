/* eslint-disable class-methods-use-this */

import $ from 'jquery';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { InfiniteScroller } from '~/infinite_scroller';
import axios from '~/lib/utils/axios_utils';
import { removeParams } from '~/lib/utils/url_utility';
import { localTimeAgo } from './lib/utils/datetime_utility';

export default class Activities {
  constructor(containerSelector = '') {
    this.containerSelector = containerSelector;
    this.containerEl = this.containerSelector
      ? document.querySelector(this.containerSelector)
      : undefined;
    this.$contentList = $('.content_list');

    this.loadActivities();

    $('.event-filter-link').on('click', this.toggleFilter.bind(this));
  }

  loadActivities() {
    const limit = 20;
    this.scroller = new InfiniteScroller({
      root: (this.containerEl || document).querySelector('.js-infinite-scrolling-root'),
      fetchNextPage: async (offset, signal) => {
        return axios
          .get(this.$contentList.data('href') || removeParams(['limit', 'offset']), {
            params: { limit, offset },
            signal,
          })
          .then(({ data: { count, html } }) => ({ count, html }))
          .catch((error) => {
            if (axios.isCancel(error)) return null;
            createAlert({
              message: s__(
                'Activity|An error occurred while retrieving activity. Reload the page to try again.',
              ),
              parent: this.containerEl,
            });
            throw error;
          });
      },
      limit,
    });
    this.scroller.initialize();
    this.scroller.eventTarget.addEventListener(
      InfiniteScroller.events.htmlInserted,
      this.updateTooltips,
    );
  }

  updateTooltips() {
    localTimeAgo(document.querySelectorAll('.content_list .js-timeago'));
  }

  reloadActivities() {
    this.$contentList.html('');
    this.scroller.eventTarget.removeEventListener(
      InfiniteScroller.events.htmlInserted,
      this.updateTooltips,
    );
    this.scroller.destroy();
    this.loadActivities();
  }

  toggleFilter(event) {
    event.preventDefault();
    const $sender = $(event.currentTarget);
    const filter = $sender.attr('id').split('_')[0];
    if (getCookie('event_filter') === filter) return;
    setCookie('event_filter', filter);
    $('.event-filter .active').removeClass('active');
    $sender.closest('li').toggleClass('active');
    this.reloadActivities(filter);
  }
}
