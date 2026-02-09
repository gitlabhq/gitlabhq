import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import createDefaultClient from '~/lib/graphql';
import { parseBooleanDataAttributes } from '~/lib/utils/dom_utils';
import SecurityConfigurationApp from './components/app.vue';
import SecurityConfigurationProvider from './components/security_configuration_provider.vue';
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

  const { projectId, projectFullPath, useGraphql } = el.dataset;

  // Use GraphQL mode when explicitly enabled (e.g., from drawer)
  const shouldUseGraphql = parseBoolean(useGraphql);

  if (shouldUseGraphql) {
    return new Vue({
      el,
      apolloProvider,
      name: 'SecurityConfigurationRoot',
      provide: {
        projectId,
        projectFullPath,
      },
      render(createElement) {
        return createElement(SecurityConfigurationProvider);
      },
    });
  }

  // Legacy mode: use server-rendered data
  const {
    groupFullPath,
    canApplyProfiles,
    canReadAttributes,
    canManageAttributes,
    securityScanProfilesLicensed,
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
    maxTrackedRefs,
  } = el.dataset;

  const { augmentedSecurityFeatures } = augmentFeatures(features ? JSON.parse(features) : []);

  return new Vue({
    el,
    apolloProvider,
    name: 'SecurityConfigurationRoot',
    provide: {
      projectFullPath,
      groupFullPath,
      canApplyProfiles: parseBoolean(canApplyProfiles),
      canReadAttributes: parseBoolean(canReadAttributes),
      canManageAttributes: parseBoolean(canManageAttributes),
      securityScanProfilesLicensed: parseBoolean(securityScanProfilesLicensed),
      groupManageAttributesPath,
      upgradePath,
      autoDevopsHelpPagePath,
      autoDevopsPath,
      vulnerabilityTrainingDocsPath,
      containerScanningForRegistryEnabled,
      vulnerabilityArchiveExportPath,
      secretDetectionConfigurationPath,
      licenseConfigurationSource,
      maxTrackedRefs: Number(maxTrackedRefs, 10),
      ...parseBooleanDataAttributes(el, [
        'secretPushProtectionAvailable',
        'secretPushProtectionEnabled',
        'validityChecksAvailable',
        'validityChecksEnabled',
        'userIsProjectAdmin',
        'secretPushProtectionLicensed',
        'canEnableSpp',
        'isGitlabCom',
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
