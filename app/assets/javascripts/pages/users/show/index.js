import { initProfileTabs, initUserAchievements } from '~/profile';

if (gon.features?.profileTabsVue) {
  initProfileTabs();
}

initUserAchievements();
