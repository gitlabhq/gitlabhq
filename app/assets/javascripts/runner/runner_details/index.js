import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RunnerDetailsApp from './runner_details_app.vue';

Vue.use(VueApollo);

export const initRunnerDetail = (selector = '#js-runner-details') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId } = el.dataset;

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
    render(h) {
      return h(RunnerDetailsApp, {
        props: {
          runnerId,
        },
      });
    },
  });
};
