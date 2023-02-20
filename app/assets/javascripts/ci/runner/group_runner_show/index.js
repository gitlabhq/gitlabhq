import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createDefaultClient from '~/lib/graphql';
import { showAlertFromLocalStorage } from '../local_storage_alert/show_alert_from_local_storage';
import GroupRunnerShowApp from './group_runner_show_app.vue';

Vue.use(VueApollo);
Vue.use(VueRouter);

export const initGroupRunnerShow = (selector = '#js-group-runner-show') => {
  showAlertFromLocalStorage();

  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnersPath, editGroupRunnerPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(GroupRunnerShowApp, {
        props: {
          runnerId,
          runnersPath,
          editGroupRunnerPath,
        },
      });
    },
  });
};
