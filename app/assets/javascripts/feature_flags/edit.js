import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

import EditFeatureFlag from './components/edit_feature_flag.vue';
import createStore from './store/edit';

Vue.use(Vuex);

export default () => {
  const el = document.querySelector('#js-edit-feature-flag');
  const {
    environmentsScopeDocsPath,
    strategyTypeDocsPagePath,
    endpoint,
    featureFlagsPath,
    environmentsEndpoint,
    projectId,
    featureFlagIssuesEndpoint,
    searchPath,
  } = el.dataset;

  return initVueApp({
    el,
    name: 'EditFeatureFlagRoot',
    store: createStore({ endpoint, projectId, path: featureFlagsPath }),
    provide: {
      environmentsScopeDocsPath,
      strategyTypeDocsPagePath,
      environmentsEndpoint,
      projectId,
      featureFlagIssuesEndpoint,
      searchPath,
    },
    component: EditFeatureFlag,
  });
};
