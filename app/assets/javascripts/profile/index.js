import Vue from 'vue';

import ProfileTabs from './components/profile_tabs.vue';

export const initProfileTabs = () => {
  const el = document.getElementById('js-profile-tabs');

  if (!el) return false;

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProfileTabs);
    },
  });
};
