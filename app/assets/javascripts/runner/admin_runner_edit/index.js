import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AdminRunnerEditApp from './admin_runner_edit_app.vue';

Vue.use(VueApollo);

export const initAdminRunnerEdit = (selector = '#js-admin-runner-edit') => {
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
      return h(AdminRunnerEditApp, {
        props: {
          runnerId,
        },
      });
    },
  });
};
