import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import createStore from './store/new';
import NewFeatureFlag from './components/new_feature_flag.vue';

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
