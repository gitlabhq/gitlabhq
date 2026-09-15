import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectId, projectFullPath, useGraphql } = el.dataset;

  // Use GraphQL mode when explicitly enabled (e.g., from drawer)
  const shouldUseGraphql = parseBoolean(useGraphql);

  if (shouldUseGraphql) {
    return initVueApp({
      el,
      apolloProvider,
      name: 'SecurityConfigurationRoot',
      provide: {
        projectId,
        projectFullPath,
      },
      component: SecurityConfigurationProvider,
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
    features,
    latestPipelinePath,
    gitlabCiHistoryPath,
    autoDevopsHelpPagePath,
    autoDevopsPath,
    vulnerabilityTrainingDocsPath,
    secretDetectionConfigurationPath,
    vulnerabilityArchiveExportPath,
    licenseConfigurationSource,
    maxTrackedRefs,
  } = el.dataset;

  const { augmentedSecurityFeatures } = augmentFeatures(features ? JSON.parse(features) : []);

  return initVueApp({
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
      autoDevopsHelpPagePath,
      autoDevopsPath,
      vulnerabilityTrainingDocsPath,
      vulnerabilityArchiveExportPath,
      secretDetectionConfigurationPath,
      licenseConfigurationSource,
      maxTrackedRefs: Number(maxTrackedRefs, 10),
      ...parseBooleanDataAttributes(el, [
        'secretPushProtectionAvailable',
        'secretPushProtectionEnabled',
        'secretPushProtectionEnforced',
        'validityChecksAvailable',
        'validityChecksEnabled',
        'userIsProjectAdmin',
        'cvsForContainerScanningEnabled',
        'cvsForDependencyScanningEnabled',
        'licenseScanningForCyclonedxEnabled',
      ]),
    },
    component: SecurityConfigurationApp,
    props: {
      augmentedSecurityFeatures,
      latestPipelinePath,
      gitlabCiHistoryPath,
      ...parseBooleanDataAttributes(el, [
        'gitlabCiPresent',
        'autoDevopsEnabled',
        'canEnableAutoDevops',
        'securityTrainingEnabled',
        'mergeRequestsEnabled',
      ]),
    },
  });
};
