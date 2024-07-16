import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import UserActionsApp from './components/user_actions_app.vue';

export const initUserActionsApp = () => {
  const mountingEl = document.querySelector('.js-user-profile-actions');

  if (!mountingEl) return false;

  const { userId, rssSubscriptionPath, reportAbusePath, reportedUserId, reportedFromUrl } =
    mountingEl.dataset;

  Vue.use(GlToast);

  return new Vue({
    el: mountingEl,
    name: 'UserActionsRoot',
    provide: {
      reportAbusePath,
    },
    render(createElement) {
      return createElement(UserActionsApp, {
        props: {
          userId,
          rssSubscriptionPath,
          reportedUserId: reportedUserId ? parseInt(reportedUserId, 10) : null,
          reportedFromUrl,
        },
      });
    },
  });
};
