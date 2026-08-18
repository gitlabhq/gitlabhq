import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el,
    name: 'RunnerEditAppRoot',
    apolloProvider,
    component: RunnerEditApp,
    props: {
      runnerId,
      runnerPath,
    },
  });
};
