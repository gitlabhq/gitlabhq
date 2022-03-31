import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { visitUrl } from '~/lib/utils/url_utility';
import { updateOutdatedUrl } from '~/runner/runner_search_utils';
import createDefaultClient from '~/lib/graphql';
import { createLocalState } from '../graphql/list/local_state';
import AdminRunnersApp from './admin_runners_app.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

export const initAdminRunners = (selector = '#js-admin-runners') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  // Redirect outdated URLs
  const updatedUrlQuery = updateOutdatedUrl();
  if (updatedUrlQuery) {
    visitUrl(updatedUrlQuery);

    // Prevent mounting the rest of the app, redirecting now.
    return null;
  }

  const {
    runnerInstallHelpPage,
    registrationToken,
    onlineContactTimeoutSecs,
    staleTimeoutSecs,
  } = el.dataset;

  const { cacheConfig, typeDefs, localMutations } = createLocalState();

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { cacheConfig, typeDefs }),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      runnerInstallHelpPage,
      localMutations,
      onlineContactTimeoutSecs,
      staleTimeoutSecs,
    },
    render(h) {
      return h(AdminRunnersApp, {
        props: {
          registrationToken,
        },
      });
    },
  });
};
