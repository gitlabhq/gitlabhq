import $ from 'jquery';
import Cookies from 'js-cookie';
import Pager from './pager';
import { localTimeAgo } from './lib/utils/datetime_utility';

export default class Activities {
  constructor() {
    Pager.init(20, true, false, data => data, Activities.updateTooltips);

    $('.event-filter-link').on('click', e => {
      e.preventDefault();
      Activities.toggleFilter(e.currentTarget);
      Activities.reloadActivities();
    });
  }

  static updateTooltips() {
    localTimeAgo($('.js-timeago', '.content_list'));
  }

  static reloadActivities() {
    $('.content_list').html('');
    Pager.init(20, true, false, data => data, Activities.updateTooltips);
  }

  static toggleFilter(sender) {
    const $sender = $(sender);
    const filter = $sender.attr('id').split('_')[0];

    $('.event-filter .active').removeClass('active');
    Cookies.set('event_filter', filter);

    $sender.closest('li').toggleClass('active');
  }
}
