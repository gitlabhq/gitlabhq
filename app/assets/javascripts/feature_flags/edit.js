import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
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

  return new Vue({
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
    render(createElement) {
      return createElement(EditFeatureFlag);
    },
  });
};
