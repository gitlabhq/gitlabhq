import Vue from 'vue';
import Vuex from 'vuex';
import csrf from '~/lib/utils/csrf';
import FeatureFlagsComponent from './components/feature_flags.vue';
import createStore from './store/index';

Vue.use(Vuex);

export default () => {
  const el = document.querySelector('#feature-flags-vue');

  const {
    projectName,
    featureFlagsHelpPagePath,
    errorStateSvgPath,
    endpoint,
    projectId,
    unleashApiInstanceId,
    rotateInstanceIdPath,
  } = el.dataset;

  return new Vue({
    el,
    store: createStore({ endpoint, projectId, unleashApiInstanceId, rotateInstanceIdPath }),
    provide() {
      return {
        projectName,
        featureFlagsHelpPagePath,
        errorStateSvgPath,
      };
    },
    render(createElement) {
      return createElement(FeatureFlagsComponent, {
        props: {
          featureFlagsClientLibrariesHelpPagePath:
            el.dataset.featureFlagsClientLibrariesHelpPagePath,
          featureFlagsClientExampleHelpPagePath: el.dataset.featureFlagsClientExampleHelpPagePath,
          unleashApiUrl: el.dataset.unleashApiUrl,
          csrfToken: csrf.token,
          canUserConfigure: el.dataset.canUserAdminFeatureFlag,
          newFeatureFlagPath: el.dataset.newFeatureFlagPath,
          newUserListPath: el.dataset.newUserListPath,
        },
      });
    },
  });
};
