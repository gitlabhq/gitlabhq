import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import AdminNewRunnerApp from './admin_new_runner_app.vue';

Vue.use(VueApollo);

export const initAdminNewRunner = (selector = '#js-admin-new-runner') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnersPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'AdminNewRunnerAppRoot',
    apolloProvider,
    component: AdminNewRunnerApp,
    props: {
      runnersPath,
    },
  });
};
