import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';

import createDefaultClient from '~/lib/graphql';
import { USER_PROFILE_ROUTE_NAME_DEFAULT } from '~/profile/constants';
import UserProfileApp from './components/app.vue';
import UserAchievements from './components/user_achievements.vue';
import ProfileTabs from './components/profile_tabs.vue';

Vue.use(VueApollo);
Vue.use(VueRouter);

export const createRouter = () => {
  const routes = [
    {
      name: USER_PROFILE_ROUTE_NAME_DEFAULT,
      path: '/:user*',
      component: ProfileTabs,
    },
  ];

  return new VueRouter({
    routes,
    mode: 'history',
    base: '/',
    scrollBehavior(to, from, savedPosition) {
      return savedPosition || { x: 0, y: 0 };
    },
  });
};

export const initUserProfileApp = () => {
  const el = document.getElementById('js-user-profile-app');

  if (!el) return false;

  const {
    followeesCount,
    followersCount,
    userCalendarPath,
    userActivityPath,
    utcOffset,
    userId,
    snippetsEmptyState,
    newSnippetPath,
    followEmptyState,
  } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'ProfileRoot',
    router: createRouter(),
    provide: {
      followeesCount: parseInt(followeesCount, 10),
      followersCount: parseInt(followersCount, 10),
      userCalendarPath,
      userActivityPath,
      utcOffset,
      userId,
      snippetsEmptyState,
      newSnippetPath,
      followEmptyState,
    },
    render(createElement) {
      return createElement(UserProfileApp);
    },
  });
};

export const initUserAchievements = () => {
  const el = document.getElementById('js-user-achievements');

  if (!el) return false;

  const { rootUrl, userId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    name: 'UserAchievements',
    provide: { rootUrl, userId: parseInt(userId, 10) },
    render(createElement) {
      return createElement(UserAchievements);
    },
  });
};
