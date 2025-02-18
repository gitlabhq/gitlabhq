import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import SecurityConfigurationApp from './components/app.vue';
import { augmentFeatures } from './utils';

export const initSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);
  Vue.use(GlToast);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    projectFullPath,
    upgradePath,
    features,
    latestPipelinePath,
    gitlabCiHistoryPath,
    autoDevopsHelpPagePath,
    autoDevopsPath,
    vulnerabilityTrainingDocsPath,
    containerScanningForRegistryEnabled,
    secretDetectionConfigurationPath,
  } = el.dataset;

  const { augmentedSecurityFeatures } = augmentFeatures(features ? JSON.parse(features) : []);

  return new Vue({
    el,
    apolloProvider,
    name: 'SecurityConfigurationRoot',
    provide: {
      projectFullPath,
      upgradePath,
      autoDevopsHelpPagePath,
      autoDevopsPath,
      vulnerabilityTrainingDocsPath,
      containerScanningForRegistryEnabled,
      secretDetectionConfigurationPath,
      ...parseBooleanDataAttributes(el, [
        'secretPushProtectionAvailable',
        'secretPushProtectionEnabled',
        'userIsProjectAdmin',
      ]),
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp, {
        props: {
          augmentedSecurityFeatures,
          latestPipelinePath,
          gitlabCiHistoryPath,
          ...parseBooleanDataAttributes(el, [
            'gitlabCiPresent',
            'autoDevopsEnabled',
            'canEnableAutoDevops',
            'securityTrainingEnabled',
          ]),
        },
      });
    },
  });
};
