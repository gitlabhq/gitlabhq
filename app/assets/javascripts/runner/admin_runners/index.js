import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AdminRunnersApp from './admin_runners_app.vue';

Vue.use(VueApollo);

export const initAdminRunners = (selector = '#js-admin-runners') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  // TODO `activeRunnersCount` should be implemented using a GraphQL API
  // https://gitlab.com/gitlab-org/gitlab/-/issues/333806
  const { activeRunnersCount, registrationToken, runnerInstallHelpPage } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        assumeImmutableResults: true,
      },
    ),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      runnerInstallHelpPage,
    },
    render(h) {
      return h(AdminRunnersApp, {
        props: {
          activeRunnersCount: parseInt(activeRunnersCount, 10),
          registrationToken,
        },
      });
    },
  });
};
