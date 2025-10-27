import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import resolvers from 'ee_else_ce/security_configuration/security_attributes/graphql/resolvers';
import createDefaultClient from '~/lib/graphql';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import SecurityConfigurationApp from './components/app.vue';
import { augmentFeatures } from './utils';
import typeDefs from './graphql/typedefs.graphql';

export const initSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);
  Vue.use(GlToast);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(resolvers, { typeDefs }),
  });

  const {
    projectFullPath,
    groupFullPath,
    canManageAttributes,
    groupManageAttributesPath,
    upgradePath,
    features,
    latestPipelinePath,
    gitlabCiHistoryPath,
    autoDevopsHelpPagePath,
    autoDevopsPath,
    vulnerabilityTrainingDocsPath,
    containerScanningForRegistryEnabled,
    secretDetectionConfigurationPath,
    vulnerabilityArchiveExportPath,
    licenseConfigurationSource,
  } = el.dataset;

  const { augmentedSecurityFeatures } = augmentFeatures(features ? JSON.parse(features) : []);

  return new Vue({
    el,
    apolloProvider,
    name: 'SecurityConfigurationRoot',
    provide: {
      projectFullPath,
      groupFullPath,
      canManageAttributes: parseBoolean(canManageAttributes),
      groupManageAttributesPath,
      upgradePath,
      autoDevopsHelpPagePath,
      autoDevopsPath,
      vulnerabilityTrainingDocsPath,
      containerScanningForRegistryEnabled,
      vulnerabilityArchiveExportPath,
      secretDetectionConfigurationPath,
      licenseConfigurationSource,
      ...parseBooleanDataAttributes(el, [
        'secretPushProtectionAvailable',
        'secretPushProtectionEnabled',
        'validityChecksAvailable',
        'validityChecksEnabled',
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
