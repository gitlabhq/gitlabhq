// TODO: Remove this with the removal of the old navigation.
// See https://gitlab.com/gitlab-org/gitlab/-/issues/435899.

import $ from 'jquery';
import initReadMore from '~/read_more';
import Activities from '~/activities';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import ActivityCalendar from './activity_calendar';
import UserOverviewBlock from './user_overview_block';

const CALENDAR_TEMPLATE = `
  <div class="calendar">
    <div class="js-contrib-calendar gl-overflow-x-auto"></div>
    <div class="calendar-help gl-flex gl-justify-between gl-ml-auto gl-mr-auto">
      <div class="calendar-legend">
        <svg width="80px" height="20px">
          <g>
            <rect width="13" height="13" x="2" y="2" rx="2" ry="2" data-level="0" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              'No contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="17" y="2" rx="2" ry="2" data-level="1" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '1-9 contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="32" y="2" rx="2" ry="2" data-level="2" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '10-19 contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="47" y="2" rx="2" ry="2" data-level="3" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '20-29 contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="62" y="2" rx="2" ry="2" data-level="4" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '30+ contributions',
            )}" data-container="body"></rect>
          </g>
        </svg>
      </div>
      <div class="calendar-hint gl-text-sm gl-text-subtle"></div>
    </div>
  </div>
`;

const CALENDAR_PERIOD_12_MONTHS = 12;

const DEFAULT_LOADER_ACTIONS = [
  'groups',
  'contributed',
  'projects',
  'starred',
  'snippets',
  'followers',
  'following',
];

export default class UserTabs {
  constructor({ parentEl }) {
    this.$legacyTabsContainer = $('#js-legacy-tabs-container');
    this.$parentEl = $(parentEl || document);
    this.windowLocation = window.location;

    const action = this.$legacyTabsContainer.data('action');
    const endpoint = this.$legacyTabsContainer.data('endpoint');

    this.bindPaginationEvent();
    this.loadPage(action, endpoint);
  }

  bindPaginationEvent() {
    this.$parentEl.on('click', '.gl-pagination a', (event) => this.changePage(event));
  }

  changePage(e) {
    e.preventDefault();

    $('#js-legacy-tabs-container').empty();
    const endpoint = $(e.target).attr('href');
    const action = this.$legacyTabsContainer.data('action');
    this.loadPage(action, endpoint);
  }

  loadPage(action, endpoint) {
    if (action === 'activity') {
      // eslint-disable-next-line no-new
      new Activities('#js-legacy-tabs-container');
    } else if (action === 'overview') {
      this.loadOverviewPage();
    } else if (DEFAULT_LOADER_ACTIONS.includes(action)) {
      this.defaultPageLoader(action, endpoint);
    }
  }

  defaultPageLoader(action, endpoint) {
    this.toggleLoading(true);

    const params = action === 'projects' ? { skip_namespace: true } : {};

    return axios
      .get(endpoint, { params })
      .then(({ data }) => {
        const containerSelector = `div#js-legacy-tabs-container`;
        this.$parentEl.find(containerSelector).html(data.html);
        localTimeAgo(document.querySelectorAll(`${containerSelector} .js-timeago`));

        this.toggleLoading(false);
      })
      .catch(() => {
        this.toggleLoading(false);
      });
  }

  loadOverviewPage() {
    initReadMore();

    this.loadActivityCalendar();

    UserTabs.renderMostRecentBlocks('#js-legacy-tabs-container .activities-block', {
      requestParams: { limit: 15 },
    });

    UserTabs.renderMostRecentBlocks('#js-legacy-tabs-container .projects-block', {
      requestParams: { limit: 3, skip_pagination: true, skip_namespace: true, card_mode: true },
    });
  }

  static renderMostRecentBlocks(container, options) {
    if ($(container).length === 0) {
      return;
    }
    // eslint-disable-next-line no-new
    new UserOverviewBlock({
      container,
      url: $(`${container} .overview-content-list`).data('href'),
      ...options,
      postRenderCallback: () => localTimeAgo(document.querySelectorAll(`${container} .js-timeago`)),
    });
  }

  loadActivityCalendar() {
    const $calendarWrap = this.$parentEl.find('.user-calendar');
    const calendarPath = $calendarWrap.data('calendarPath');

    AjaxCache.retrieve(calendarPath)
      .then((data) => UserTabs.renderActivityCalendar(data, $calendarWrap))
      .catch(() => {
        const cWrap = $calendarWrap[0];
        cWrap.querySelector('.gl-spinner').classList.add('invisible');
        cWrap.querySelector('.user-calendar-error').classList.remove('invisible');
        cWrap
          .querySelector('.user-calendar-error .js-retry-load')
          .addEventListener('click', (e) => {
            e.preventDefault();
            cWrap.querySelector('.user-calendar-error').classList.add('invisible');
            cWrap.querySelector('.gl-spinner').classList.remove('invisible');
            this.loadActivityCalendar();
          });
      });
  }

  static renderActivityCalendar(data, $calendarWrap) {
    const calendarActivitiesPath = $calendarWrap.data('calendarActivitiesPath');
    const utcOffset = $calendarWrap.data('utcOffset');
    const calendarHint = __('Issues, merge requests, pushes, and comments.');

    $calendarWrap.html(CALENDAR_TEMPLATE);

    $calendarWrap.find('.calendar-hint').text(calendarHint);

    // eslint-disable-next-line no-new
    new ActivityCalendar({
      container: '#js-legacy-tabs-container .js-contrib-calendar',
      activitiesContainer: '#js-legacy-tabs-container .user-calendar-activities',
      recentActivitiesContainer:
        '#js-legacy-tabs-container .activities-block .user-activity-content',
      timestamps: data,
      calendarActivitiesPath,
      utcOffset,
      firstDayOfWeek: gon.first_day_of_week,
      CALENDAR_PERIOD_12_MONTHS,
    });

    // Scroll to end
    const calendarContainer = document.querySelector('.js-contrib-calendar');
    calendarContainer.scrollLeft = calendarContainer.scrollWidth;
  }

  toggleLoading(status) {
    return this.$parentEl.find('.loading').toggleClass('hide', !status);
  }
}
