import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import GroupRegisterRunnerApp from './group_register_runner_app.vue';

Vue.use(VueApollo);

export const initGroupRegisterRunner = (selector = '#js-group-register-runner') => {
  showAlertFromLocalStorage();

  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnersPath, groupPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(GroupRegisterRunnerApp, {
        props: {
          runnerId,
          runnersPath,
          groupPath,
        },
      });
    },
  });
};
