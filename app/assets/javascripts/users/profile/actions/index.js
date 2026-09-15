import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import UserActionsApp from './components/user_actions_app.vue';

export const initUserActionsApp = () => {
  const mountingEl = document.querySelector('.js-user-profile-actions');

  if (!mountingEl) return false;

  const { userId, rssSubscriptionPath, reportAbusePath, reportedUserId, reportedFromUrl } =
    mountingEl.dataset;

  return initVueApp({
    el: mountingEl,
    name: 'UserActionsRoot',
    provide: {
      reportAbusePath,
    },
    component: UserActionsApp,
    props: {
      userId,
      rssSubscriptionPath,
      reportedUserId: reportedUserId ? parseInt(reportedUserId, 10) : null,
      reportedFromUrl,
    },
  });
};
