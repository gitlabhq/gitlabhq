import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AdminRunnerShowApp from './admin_runner_show_app.vue';

Vue.use(VueApollo);

export const initAdminRunnerShow = (selector = '#js-admin-runner-show') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const { runnerId } = el.dataset;

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(AdminRunnerShowApp, {
        props: {
          runnerId,
        },
      });
    },
  });
};
