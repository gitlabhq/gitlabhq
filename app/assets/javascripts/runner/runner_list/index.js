import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RunnerDetailsApp from './runner_list_app.vue';

Vue.use(VueApollo);

export const initRunnerList = (selector = '#js-runner-list') => {
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
      return h(RunnerDetailsApp, {
        props: {
          activeRunnersCount: parseInt(activeRunnersCount, 10),
          registrationToken,
        },
      });
    },
  });
};
