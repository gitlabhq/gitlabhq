import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import ProjectRegisterRunnerApp from './project_register_runner_app.vue';

Vue.use(VueApollo);

export const initProjectRegisterRunner = (selector = '#js-project-register-runner') => {
  showAlertFromLocalStorage();

  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId, runnersPath, projectPath } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(ProjectRegisterRunnerApp, {
        props: {
          runnerId,
          runnersPath,
          projectPath,
        },
      });
    },
  });
};
