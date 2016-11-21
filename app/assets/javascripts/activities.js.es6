/* eslint-disable no-param-reassign, class-methods-use-this */
/* global Pager */
/* global Cookies */

((global) => {
  class Activities {
    constructor() {
      Pager.init(20, true, false, this.updateTooltips);
      $('.event-filter-link').on('click', (e) => {
        e.preventDefault();
        this.toggleFilter(e.currentTarget);
        this.reloadActivities();
      });
    }

    updateTooltips() {
      gl.utils.localTimeAgo($('.js-timeago', '.content_list'));
    }

    reloadActivities() {
      $('.content_list').html('');
      Pager.init(20, true, false, this.updateTooltips);
    }

    toggleFilter(sender) {
      const $sender = $(sender);
      const filter = $sender.attr('id').split('_')[0];

      $('.event-filter .active').removeClass('active');
      Cookies.set('event_filter', filter);

      $sender.closest('li').toggleClass('active');
    }
  }

  global.Activities = Activities;
})(window.gl || (window.gl = {}));
