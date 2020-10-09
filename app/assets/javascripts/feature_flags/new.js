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
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({ endpoint, path: featureFlagsPath }),
    provide: {
      environmentsScopeDocsPath,
      strategyTypeDocsPagePath,
    },
    render(createElement) {
      return createElement(NewFeatureFlag, {
        props: {
          environmentsEndpoint: el.dataset.environmentsEndpoint,
          projectId: el.dataset.projectId,
          userCalloutsPath: el.dataset.userCalloutsPath,
          userCalloutId: el.dataset.userCalloutId,
          showUserCallout: parseBoolean(el.dataset.showUserCallout),
        },
      });
    },
  });
};
