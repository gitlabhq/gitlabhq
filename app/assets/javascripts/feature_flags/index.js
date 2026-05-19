import Vue from 'vue';
import csrf from '~/lib/utils/csrf';
import { pinia } from '~/pinia/instance';
import FeatureFlagsComponent from './components/feature_flags.vue';
import { useFeatureFlags } from './store/index';

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
    featureFlagsClientLibrariesHelpPagePath,
    featureFlagsClientExampleHelpPagePath,
    unleashApiUrl,
    canUserAdminFeatureFlag,
    newFeatureFlagPath,
    userListPath,
    featureFlagsLimitExceeded,
    featureFlagsLimit,
  } = el.dataset;

  useFeatureFlags(pinia).setInitialState({
    endpoint,
    projectId,
    unleashApiInstanceId,
    rotateInstanceIdPath,
  });

  return new Vue({
    el,
    name: 'FeatureFlagsComponentRoot',
    pinia,
    provide: {
      projectName,
      featureFlagsHelpPagePath,
      errorStateSvgPath,
      featureFlagsClientLibrariesHelpPagePath,
      featureFlagsClientExampleHelpPagePath,
      unleashApiUrl,
      csrfToken: csrf.token,
      canUserConfigure: canUserAdminFeatureFlag !== undefined,
      newFeatureFlagPath,
      featureFlagsLimitExceeded: featureFlagsLimitExceeded !== undefined,
      featureFlagsLimit,
      userListPath,
    },
    render(createElement) {
      return createElement(FeatureFlagsComponent);
    },
  });
};
