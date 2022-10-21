import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RunnerEditApp from './runner_edit_app.vue';

Vue.use(VueApollo);

export const initRunnerEdit = (selector) => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnerPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(RunnerEditApp, {
        props: {
          runnerId,
          runnerPath,
        },
      });
    },
  });
};
