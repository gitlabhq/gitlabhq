import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import NewFeatureFlag from './components/new_feature_flag.vue';
import createStore from './store/new';

Vue.use(Vuex);

export default () => {
  const el = document.querySelector('#js-new-feature-flag');
  const {
    environmentsScopeDocsPath,
    strategyTypeDocsPagePath,
    endpoint,
    featureFlagsPath,
    environmentsEndpoint,
    projectId,
    userCalloutsPath,
    userCalloutId,
    showUserCallout,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({ endpoint, projectId, path: featureFlagsPath }),
    provide: {
      environmentsScopeDocsPath,
      strategyTypeDocsPagePath,
      environmentsEndpoint,
      projectId,
      userCalloutsPath,
      userCalloutId,
      showUserCallout: parseBoolean(showUserCallout),
    },
    render(createElement) {
      return createElement(NewFeatureFlag);
    },
  });
};
