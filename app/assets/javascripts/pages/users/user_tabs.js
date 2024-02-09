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
 *     <a data-action="activity" data-target="#activity" data-toggle="tab" href="/username">
 *       Activity
 *     </a>
 *   </li>
 *   <li class="groups-tab">
 *     <a data-action="groups" data-target="#groups" data-toggle="tab" href="/users/username/groups">
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
 * <div class="loading">
 *   Loading Animation
 * </div>
 */

const CALENDAR_TEMPLATE = `
  <div class="calendar">
    <div class="js-contrib-calendar gl-overflow-x-auto"></div>
    <div class="calendar-help gl-display-flex gl-justify-content-space-between gl-ml-auto gl-mr-auto">
      <div class="calendar-legend">
        <svg width="80px" height="20px">
          <g>
            <rect width="13" height="13" x="2" y="2" data-level="0" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              'No contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="17" y="2" data-level="1" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '1-9 contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="32" y="2" data-level="2" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '10-19 contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="47" y="2" data-level="3" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '20-29 contributions',
            )}" data-container="body"></rect>
            <rect width="13" height="13" x="62" y="2" data-level="4" class="user-contrib-cell has-tooltip contrib-legend" title="${__(
              '30+ contributions',
            )}" data-container="body"></rect>
          </g>
        </svg>
      </div>
      <div class="calendar-hint gl-font-sm gl-text-secondary"></div>
    </div>
  </div>
`;

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

    // TODO: refactor to make this configurable via constructor params with a default value of 'show'
    if (this.action === 'show') {
      this.action = this.defaultAction;
    }

    this.activateTab(this.action);
  }

  bindEvents() {
    this.$parentEl
      .off('shown.bs.tab', '.nav-links a[data-toggle="tab"]')
      .on('shown.bs.tab', '.nav-links a[data-toggle="tab"]', (event) => this.tabShown(event))
      .on('click', '.gl-pagination a', (event) => this.changeProjectsPage(event));
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

    const loadableActions = [
      'groups',
      'contributed',
      'projects',
      'starred',
      'snippets',
      'followers',
      'following',
    ];
    if (loadableActions.indexOf(action) > -1) {
      this.loadTab(action, endpoint);
    }
  }

  loadTab(action, endpoint) {
    this.toggleLoading(true);

    const params = action === 'projects' ? { skip_namespace: true } : {};

    return axios
      .get(endpoint, { params })
      .then(({ data }) => {
        const tabSelector = `div#${action}`;
        this.$parentEl.find(tabSelector).html(data.html);
        this.loaded[action] = true;
        localTimeAgo(document.querySelectorAll(`${tabSelector} .js-timeago`));

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

    // eslint-disable-next-line no-new
    new Activities('#activity');

    this.loaded.activity = true;
  }

  loadOverviewTab() {
    if (this.loaded.overview) {
      return;
    }

    initReadMore();

    this.loadActivityCalendar();

    UserTabs.renderMostRecentBlocks('#js-overview .activities-block', {
      requestParams: { limit: 15 },
    });

    UserTabs.renderMostRecentBlocks('#js-overview .projects-block', {
      requestParams: { limit: 3, skip_pagination: true, skip_namespace: true, card_mode: true },
    });

    this.loaded.overview = true;
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
    const $calendarWrap = this.$parentEl.find('.tab-pane.active .user-calendar');
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
      container: '.tab-pane.active .js-contrib-calendar',
      activitiesContainer: '.tab-pane.active .user-calendar-activities',
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
