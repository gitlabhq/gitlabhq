<script>
import { computed } from 'vue';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import securityConfigurationQuery from '../graphql/security_configuration.query.graphql';
import projectMergeRequestsEnabledQuery from '../graphql/project_merge_requests_enabled.query.graphql';
import { augmentFeatures } from '../utils';
import SecurityConfigurationApp from './app.vue';

export default {
  name: 'SecurityConfigurationProvider',
  components: {
    SecurityConfigurationApp,
    GlAlert,
    GlLoadingIcon,
  },
  inject: ['projectId', 'projectFullPath'],
  provide() {
    return {
      projectFullPath: this.projectFullPath,
      vulnerabilityTrainingDocsPath: computed(
        () => this.graphqlData?.vulnerabilityTrainingDocsPath || '',
      ),
      upgradePath: computed(() => this.graphqlData?.upgradePath || ''),
      groupFullPath: computed(() => this.graphqlData?.groupFullPath || ''),
      canApplyProfiles: computed(() => this.graphqlData?.canApplyProfiles ?? false),
      canReadAttributes: computed(() => this.graphqlData?.canReadAttributes ?? false),
      canManageAttributes: computed(() => this.graphqlData?.canManageAttributes ?? false),
      securityScanProfilesLicensed: computed(
        () => this.graphqlData?.securityScanProfilesLicensed ?? false,
      ),
      groupManageAttributesPath: computed(() => this.graphqlData?.groupManageAttributesPath || ''),
      autoDevopsHelpPagePath: computed(() => this.graphqlData?.autoDevopsHelpPagePath || ''),
      autoDevopsPath: computed(() => this.graphqlData?.autoDevopsPath || ''),
      containerScanningForRegistryEnabled: computed(
        () => this.graphqlData?.containerScanningForRegistryEnabled ?? false,
      ),
      vulnerabilityArchiveExportPath: computed(
        () => this.graphqlData?.vulnerabilityArchiveExportPath || '',
      ),
      secretDetectionConfigurationPath: computed(
        () => this.graphqlData?.secretDetectionConfigurationPath || '',
      ),
      licenseConfigurationSource: computed(
        () => this.graphqlData?.licenseConfigurationSource || '',
      ),
      secretPushProtectionAvailable: computed(
        () => this.graphqlData?.secretPushProtectionAvailable ?? false,
      ),
      secretPushProtectionEnforced: computed(
        () => this.graphqlData?.secretPushProtectionEnforced ?? false,
      ),
      secretPushProtectionEnabled: computed(
        () => this.graphqlData?.secretPushProtectionEnabled ?? false,
      ),
      validityChecksAvailable: computed(() => this.graphqlData?.validityChecksAvailable ?? false),
      validityChecksEnabled: computed(() => this.graphqlData?.validityChecksEnabled ?? false),
      userIsProjectAdmin: computed(() => this.graphqlData?.userIsProjectAdmin ?? false),
    };
  },
  data() {
    return {
      graphqlData: null,
      graphqlError: null,
      // eslint-disable-next-line vue/no-unused-properties
      securityConfiguration: null,
      mergeRequestsEnabled: true,
    };
  },
  apollo: {
    securityConfiguration: {
      query: securityConfigurationQuery,
      variables() {
        return {
          projectId: convertToGraphQLId(TYPENAME_PROJECT, this.projectId),
        };
      },
      update(data) {
        if (!data?.securityConfiguration) {
          return null;
        }

        const { securityConfiguration: config } = data;
        const { augmentedSecurityFeatures } = augmentFeatures(config.features);

        this.graphqlData = {
          augmentedSecurityFeatures,
          gitlabCiPresent: config.gitlabCiPresent,
          autoDevopsEnabled: config.autoDevopsEnabled,
          canEnableAutoDevops: config.canEnableAutoDevops,
          gitlabCiHistoryPath: config.gitlabCiHistoryPath,
          latestPipelinePath: config.latestPipelinePath,
          securityTrainingEnabled: config.securityTrainingEnabled,
          autoDevopsHelpPagePath: config.autoDevopsHelpPagePath,
          autoDevopsPath: config.autoDevopsPath,
          helpPagePath: config.helpPagePath,
          containerScanningForRegistryEnabled: config.containerScanningForRegistryEnabled,
          secretPushProtectionAvailable: config.secretPushProtectionAvailable,
          secretPushProtectionEnforced: config.secretPushProtectionEnforced,
          secretPushProtectionEnabled: config.secretPushProtectionEnabled,
          validityChecksAvailable: config.validityChecksAvailable,
          validityChecksEnabled: config.validityChecksEnabled,
          userIsProjectAdmin: config.userIsProjectAdmin,
          secretDetectionConfigurationPath: config.secretDetectionConfigurationPath,
          licenseConfigurationSource: config.licenseConfigurationSource,
          vulnerabilityArchiveExportPath: config.vulnerabilityArchiveExportPath,
          vulnerabilityTrainingDocsPath: config.vulnerabilityTrainingDocsPath,
          upgradePath: config.upgradePath,
          groupFullPath: config.groupFullPath,
          canApplyProfiles: config.canApplyProfiles,
          canReadAttributes: config.canReadAttributes,
          canManageAttributes: config.canManageAttributes,
          securityScanProfilesLicensed: config.securityScanProfilesLicensed,
          groupManageAttributesPath: config.groupManageAttributesPath,
          mergeRequestsEnabled: this.mergeRequestsEnabled,
        };

        return config;
      },
      error(error) {
        this.graphqlError = error;
      },
      skip() {
        return !this.projectId;
      },
    },
    mergeRequestsEnabled: {
      query: projectMergeRequestsEnabledQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
        };
      },
      update: (data) => data.project?.mergeRequestsEnabled ?? true,
      skip() {
        return !this.projectFullPath;
      },
      error(error) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('Failed to fetch merge requests enabled status', error);
        captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return (
        (this.$apollo?.queries?.securityConfiguration?.loading ?? false) ||
        (this.$apollo?.queries?.mergeRequestsEnabled?.loading ?? false)
      );
    },
    errorMessage() {
      if (this.graphqlError) {
        return __('Failed to load security configuration');
      }
      return null;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <security-configuration-app
      v-else-if="graphqlData"
      :augmented-security-features="graphqlData.augmentedSecurityFeatures"
      :gitlab-ci-present="graphqlData.gitlabCiPresent"
      :auto-devops-enabled="graphqlData.autoDevopsEnabled"
      :can-enable-auto-devops="graphqlData.canEnableAutoDevops"
      :gitlab-ci-history-path="graphqlData.gitlabCiHistoryPath"
      :latest-pipeline-path="graphqlData.latestPipelinePath"
      :security-training-enabled="graphqlData.securityTrainingEnabled"
      :merge-requests-enabled="mergeRequestsEnabled"
    />
  </div>
</template>
