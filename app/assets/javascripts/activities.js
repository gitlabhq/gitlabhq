/* eslint-disable class-methods-use-this */

import $ from 'jquery';
import Cookies from 'js-cookie';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import { localTimeAgo } from './lib/utils/datetime_utility';
import Pager from './pager';

export default class Activities {
  constructor(containerSelector = '') {
    this.containerSelector = containerSelector;
    this.containerEl = this.containerSelector
      ? document.querySelector(this.containerSelector)
      : undefined;
    this.$contentList = $('.content_list');

    this.loadActivities();

    $('.event-filter-link').on('click', (e) => {
      e.preventDefault();
      this.toggleFilter(e.currentTarget);
      this.reloadActivities();
    });
  }

  loadActivities() {
    Pager.init({
      limit: 20,
      preload: true,
      prepareData: (data) => data,
      successCallback: () => this.updateTooltips(),
      errorCallback: () =>
        createFlash({
          message: s__(
            'Activity|An error occured while retrieving activity. Reload the page to try again.',
          ),
          parent: this.containerEl,
        }),
      container: this.containerSelector,
    });
  }

  updateTooltips() {
    localTimeAgo(document.querySelectorAll('.content_list .js-timeago'));
  }

  reloadActivities() {
    this.$contentList.html('');
    this.loadActivities();
  }

  toggleFilter(sender) {
    const $sender = $(sender);
    const filter = $sender.attr('id').split('_')[0];

    $('.event-filter .active').removeClass('active');
    Cookies.set('event_filter', filter);

    $sender.closest('li').toggleClass('active');
  }
}
