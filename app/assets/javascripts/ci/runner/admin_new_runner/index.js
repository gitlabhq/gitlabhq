import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AdminNewRunnerApp from './admin_new_runner_app.vue';

Vue.use(VueApollo);

export const initAdminNewRunner = (selector = '#js-admin-new-runner') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(AdminNewRunnerApp);
    },
  });
};
