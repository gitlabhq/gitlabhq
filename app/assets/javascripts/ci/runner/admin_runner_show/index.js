import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import AdminRunnerShowApp from './admin_runner_show_app.vue';

Vue.use(VueApollo);
Vue.use(VueRouter);

export const initAdminRunnerShow = (selector = '#js-admin-runner-show') => {
  showAlertFromLocalStorage();

  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnersPath, editPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    el,
    name: 'AdminRunnerShowAppRoot',
    apolloProvider,
    component: AdminRunnerShowApp,
    props: {
      runnerId,
      runnersPath,
      editPath,
    },
  });
};
