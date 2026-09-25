import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';

export const initVueActivityCalendar = () => {
  const el = document.getElementById('js-vue-activity-calendar');

  if (!el) {
    return null;
  }

  const {
    username,
    calendarActivitiesPath,
    activityPath,
    viewAllActivityPath,
    isCurrentUserProfile,
    emptyStateSvgPath,
    newGroupPath,
    exploreGroupsPath,
    utcOffset,
  } = el.dataset;

  return new Vue({
    el,
    name: 'VueActivityCalendarRoot',
    provide: {
      username,
      userCalendarActivitiesPath: calendarActivitiesPath,
      userActivityPath: activityPath,
      viewAllActivityPath,
      isCurrentUserProfile: parseBoolean(isCurrentUserProfile),
      emptyStateSvgPath,
      newGroupPath,
      exploreGroupsPath,
      utcOffset,
    },
    render(createElement) {
      return createElement(ActivityCalendar);
    },
  });
};
