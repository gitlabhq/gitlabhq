import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import Activities from '~/activities';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';
import flash from '~/flash';
import ActivityCalendar from './activity_calendar';
import UserOverviewBlock from './user_overview_block';

/**
 * UserTabs
 *
 * Handles persisting and restoring the current tab selection and lazily-loading
 * content on the Users#show page.
 *
 * ### Example Markup
 *
 * <ul class="nav-links">
 *   <li class="activity-tab active">
 *     <a data-action="activity" data-target="#activity" data-toggle="tab" href="/u/username">
 *       Activity
 *     </a>
 *   </li>
 *   <li class="groups-tab">
 *     <a data-action="groups" data-target="#groups" data-toggle="tab" href="/u/username/groups">
 *       Groups
 *     </a>
 *   </li>
 *   <li class="contributed-tab">
 *     ...
 *   </li>
 *   <li class="projects-tab">
 *     ...
 *   </li>
 *   <li class="snippets-tab">
 *     ...
 *   </li>
 * </ul>
 *
 * <div class="tab-content">
 *   <div class="tab-pane" id="activity">
 *     Activity Content
 *   </div>
 *   <div class="tab-pane" id="groups">
 *     Groups Content
 *   </div>
 *   <div class="tab-pane" id="contributed">
 *     Contributed projects content
 *   </div>
 *   <div class="tab-pane" id="projects">
 *    Projects content
 *   </div>
 *   <div class="tab-pane" id="snippets">
 *     Snippets content
 *   </div>
 * </div>
 *
 * <div class="loading-status">
 *   <div class="loading">
 *     Loading Animation
 *   </div>
 * </div>
 */

const CALENDAR_TEMPLATES = {
  activity: `
    <div class="clearfix calendar">
      <div class="js-contrib-calendar"></div>
      <div class="calendar-hint bottom-right"></div>
    </div>
  `,
  overview: `
    <div class="clearfix calendar">
      <div class="calendar-hint"></div>
      <div class="js-contrib-calendar prepend-top-20"></div>
    </div>
  `,
};

const CALENDAR_PERIOD_6_MONTHS = 6;
const CALENDAR_PERIOD_12_MONTHS = 12;

export default class UserTabs {
  constructor({ defaultAction, action, parentEl }) {
    this.loaded = {};
    this.defaultAction = defaultAction || 'overview';
    this.action = action || this.defaultAction;
    this.$parentEl = $(parentEl) || $(document);
    this.windowLocation = window.location;
    this.$parentEl.find('.nav-links a').each((i, navLink) => {
      this.loaded[$(navLink).attr('data-action')] = false;
    });
    this.actions = Object.keys(this.loaded);
    this.bindEvents();

    if (this.action === 'show') {
      this.action = this.defaultAction;
    }

    this.activateTab(this.action);
  }

  bindEvents() {
    this.$parentEl
      .off('shown.bs.tab', '.nav-links a[data-toggle="tab"]')
      .on('shown.bs.tab', '.nav-links a[data-toggle="tab"]', event => this.tabShown(event))
      .on('click', '.gl-pagination a', event => this.changeProjectsPage(event));
  }

  changeProjectsPage(e) {
    e.preventDefault();

    $('.tab-pane.active').empty();
    const endpoint = $(e.target).attr('href');
    this.loadTab(this.getCurrentAction(), endpoint);
  }

  tabShown(event) {
    const $target = $(event.target);
    const action = $target.data('action');
    const source = $target.attr('href');
    const endpoint = $target.data('endpoint');
    this.setTab(action, endpoint);
    return this.setCurrentAction(source);
  }

  activateTab(action) {
    return this.$parentEl.find(`.nav-links .js-${action}-tab a`).tab('show');
  }

  setTab(action, endpoint) {
    if (this.loaded[action]) {
      return;
    }
    if (action === 'activity') {
      this.loadActivities();
    } else if (action === 'overview') {
      this.loadOverviewTab();
    }

    const loadableActions = ['groups', 'contributed', 'projects', 'snippets'];
    if (loadableActions.indexOf(action) > -1) {
      this.loadTab(action, endpoint);
    }
  }

  loadTab(action, endpoint) {
    this.toggleLoading(true);

    return axios
      .get(endpoint)
      .then(({ data }) => {
        const tabSelector = `div#${action}`;
        this.$parentEl.find(tabSelector).html(data.html);
        this.loaded[action] = true;
        localTimeAgo($('.js-timeago', tabSelector));

        this.toggleLoading(false);
      })
      .catch(() => {
        this.toggleLoading(false);
      });
  }

  loadActivities() {
    if (this.loaded.activity) {
      return;
    }

    this.loadActivityCalendar('activity');

    // eslint-disable-next-line no-new
    new Activities('#activity');

    this.loaded.activity = true;
  }

  loadOverviewTab() {
    if (this.loaded.overview) {
      return;
    }

    this.loadActivityCalendar('overview');

    UserTabs.renderMostRecentBlocks('#js-overview .activities-block', {
      requestParams: { limit: 5 },
    });
    UserTabs.renderMostRecentBlocks('#js-overview .projects-block', {
      requestParams: { limit: 10, skip_pagination: true },
    });

    this.loaded.overview = true;
  }

  static renderMostRecentBlocks(container, options) {
    // eslint-disable-next-line no-new
    new UserOverviewBlock({
      container,
      url: $(`${container} .overview-content-list`).data('href'),
      ...options,
    });
  }

  loadActivityCalendar(action) {
    const monthsAgo = action === 'overview' ? CALENDAR_PERIOD_6_MONTHS : CALENDAR_PERIOD_12_MONTHS;
    const $calendarWrap = this.$parentEl.find('.tab-pane.active .user-calendar');
    const calendarPath = $calendarWrap.data('calendarPath');
    const calendarActivitiesPath = $calendarWrap.data('calendarActivitiesPath');
    const utcOffset = $calendarWrap.data('utcOffset');
    let utcFormatted = 'UTC';
    if (utcOffset !== 0) {
      utcFormatted = `UTC${utcOffset > 0 ? '+' : ''}${utcOffset / 3600}`;
    }

    axios
      .get(calendarPath)
      .then(({ data }) => {
        $calendarWrap.html(CALENDAR_TEMPLATES[action]);

        let calendarHint = '';

        if (action === 'activity') {
          calendarHint = sprintf(
            __(
              'Summary of issues, merge requests, push events, and comments (Timezone: %{utcFormatted})',
            ),
            { utcFormatted },
          );
        } else if (action === 'overview') {
          calendarHint = __('Issues, merge requests, pushes and comments.');
        }

        $calendarWrap.find('.calendar-hint').text(calendarHint);

        // eslint-disable-next-line no-new
        new ActivityCalendar(
          '.tab-pane.active .js-contrib-calendar',
          '.tab-pane.active .user-calendar-activities',
          data,
          calendarActivitiesPath,
          utcOffset,
          0,
          monthsAgo,
        );
      })
      .catch(() => flash(__('There was an error loading users activity calendar.')));
  }

  toggleLoading(status) {
    return this.$parentEl.find('.loading-status .loading').toggleClass('hide', !status);
  }

  setCurrentAction(source) {
    let newState = source;
    newState = newState.replace(/\/+$/, '');
    newState += this.windowLocation.search + this.windowLocation.hash;
    window.history.replaceState(
      {
        url: newState,
      },
      document.title,
      newState,
    );
    return newState;
  }

  getCurrentAction() {
    return this.$parentEl.find('.nav-links a.active').data('action');
  }
}
