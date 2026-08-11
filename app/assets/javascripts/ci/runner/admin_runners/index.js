import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import { runnersAppProvide } from 'ee_else_ce/ci/runner/provide';

import { visitUrl } from '~/lib/utils/url_utility';
import { updateOutdatedUrl } from '~/ci/runner/runner_search_utils';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import { createLocalState } from '../graphql/list/local_state';
import AdminRunnersApp from './admin_runners_app.vue';

Vue.use(VueApollo);

export const initAdminRunners = (selector = '#js-admin-runners') => {
  showAlertFromLocalStorage();

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
    newRunnerPath,
    runnerSettingsPath,
    allowRegistrationToken,
    registrationToken,
    tagSuggestionsPath,
    canAdminRunners,
  } = el.dataset;
  const { cacheConfig, typeDefs, localMutations } = createLocalState();

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { cacheConfig, typeDefs }),
  });

  return initVueApp({
    el,
    name: 'AdminRunnersAppRoot',
    apolloProvider,
    provide: {
      ...runnersAppProvide(el.dataset),
      localMutations,
      tagSuggestionsPath,
    },
    component: AdminRunnersApp,
    props: {
      newRunnerPath,
      runnerSettingsPath,
      allowRegistrationToken: parseBoolean(allowRegistrationToken),
      registrationToken,
      canAdminRunners: parseBoolean(canAdminRunners),
    },
  });
};
