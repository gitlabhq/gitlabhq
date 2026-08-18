import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import createDefaultClient from '~/lib/graphql';
import UserAchievements from './components/user_achievements.vue';

Vue.use(VueApollo);

export const initUserAchievements = () => {
  const el = document.getElementById('js-user-achievements');

  if (!el) return false;

  const { rootUrl, userId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    apolloProvider,
    name: 'UserAchievements',
    provide: { rootUrl, userId: parseInt(userId, 10) },
    component: UserAchievements,
  });
};
