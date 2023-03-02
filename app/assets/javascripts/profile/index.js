import Vue from 'vue';

import ProfileTabs from './components/profile_tabs.vue';

export const initProfileTabs = () => {
  const el = document.getElementById('js-profile-tabs');

  if (!el) return false;

  const { userCalendarPath, utcOffset } = el.dataset;

  return new Vue({
    el,
    provide: {
      userCalendarPath,
      utcOffset,
    },
    render(createElement) {
      return createElement(ProfileTabs);
    },
  });
};
