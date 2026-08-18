import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import AdminRegisterRunnerApp from './admin_register_runner_app.vue';

Vue.use(VueApollo);

export const initAdminRegisterRunner = (selector = '#js-admin-register-runner') => {
  showAlertFromLocalStorage();

  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnersPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'AdminRegisterRunnerAppRoot',
    apolloProvider,
    component: AdminRegisterRunnerApp,
    props: {
      runnerId,
      runnersPath,
    },
  });
};
