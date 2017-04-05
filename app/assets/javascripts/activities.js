/* eslint-disable no-param-reassign, class-methods-use-this */
/* global Pager */

import Cookies from 'js-cookie';

class Activities {
  constructor() {
    this.emptyState = document.querySelector('#js-activities-empty-state');
    Pager.init(20, true, false, this.pagerCallback.bind(this));
    $('.event-filter-link').on('click', (e) => {
      e.preventDefault();
      this.toggleFilter(e.currentTarget);
      this.reloadActivities();
    });
  }

  pagerCallback(data) {
    if (data.count === 0 && this.emptyState) this.emptyState.classList.remove('hidden');
    this.updateTooltips();
  }

  updateTooltips() {
    gl.utils.localTimeAgo($('.js-timeago', '.content_list'));
  }

  reloadActivities() {
    $('.content_list').html('');
    return Pager.init(20, true, false, this.pagerCallback.bind(this));
  }

  toggleFilter(sender) {
    const $sender = $(sender);
    const filter = $sender.attr('id').split('_')[0];

    if (this.emptyState) this.emptyState.classList.add('hidden');

    $('.event-filter .active').removeClass('active');
    Cookies.set('event_filter', filter);

    $sender.closest('li').toggleClass('active');
  }
}

window.gl = window.gl || {};
window.gl.Activities = Activities;
