import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import createStore from './store/edit';
import EditFeatureFlag from './components/edit_feature_flag.vue';

Vue.use(Vuex);

export default () => {
  const el = document.querySelector('#js-edit-feature-flag');
  const {
    environmentsScopeDocsPath,
    strategyTypeDocsPagePath,
    endpoint,
    featureFlagsPath,
  } = el.dataset;

  return new Vue({
    store: createStore({ endpoint, path: featureFlagsPath }),
    el,
    provide: {
      environmentsScopeDocsPath,
      strategyTypeDocsPagePath,
    },
    render(createElement) {
      return createElement(EditFeatureFlag, {
        props: {
          environmentsEndpoint: el.dataset.environmentsEndpoint,
          projectId: el.dataset.projectId,
          featureFlagIssuesEndpoint: el.dataset.featureFlagIssuesEndpoint,
          userCalloutsPath: el.dataset.userCalloutsPath,
          userCalloutId: el.dataset.userCalloutId,
          showUserCallout: parseBoolean(el.dataset.showUserCallout),
        },
      });
    },
  });
};
