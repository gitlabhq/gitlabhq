<script>
import { computed } from 'vue';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { __ } from '~/locale';
import securityConfigurationQuery from '../graphql/security_configuration.query.graphql';
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
      secretPushProtectionEnabled: computed(
        () => this.graphqlData?.secretPushProtectionEnabled ?? false,
      ),
      validityChecksAvailable: computed(() => this.graphqlData?.validityChecksAvailable ?? false),
      validityChecksEnabled: computed(() => this.graphqlData?.validityChecksEnabled ?? false),
      userIsProjectAdmin: computed(() => this.graphqlData?.userIsProjectAdmin ?? false),
      secretPushProtectionLicensed: computed(
        () => this.graphqlData?.secretPushProtectionLicensed ?? false,
      ),
      canEnableSpp: computed(() => this.graphqlData?.canEnableSpp ?? false),
      isGitlabCom: computed(() => this.graphqlData?.isGitlabCom ?? false),
    };
  },
  data() {
    return {
      graphqlData: null,
      graphqlError: null,
      // eslint-disable-next-line vue/no-unused-properties
      securityConfiguration: null,
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

        // Transform GraphQL response to match expected format
        const features = config.features.map((feature) => {
          const transformed = {
            type: feature.type,
            configured: feature.configured,
            configuration_path: feature.configurationPath,
            available: feature.available,
            can_enable_by_merge_request: feature.canEnableByMergeRequest,
            meta_info_path: feature.metaInfoPath,
            on_demand_available: feature.onDemandAvailable,
            anchor: feature.anchor,
          };

          if (feature.securityFeatures) {
            transformed.security_features = feature.securityFeatures;
          }

          return transformed;
        });

        const { augmentedSecurityFeatures } = augmentFeatures(features);

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
          secretPushProtectionEnabled: config.secretPushProtectionEnabled,
          secretPushProtectionLicensed: config.secretPushProtectionLicensed,
          validityChecksAvailable: config.validityChecksAvailable,
          validityChecksEnabled: config.validityChecksEnabled,
          userIsProjectAdmin: config.userIsProjectAdmin,
          canEnableSpp: config.canEnableSpp,
          isGitlabCom: config.isGitlabCom,
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
  },
  computed: {
    isLoading() {
      return this.$apollo?.queries?.securityConfiguration?.loading ?? false;
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
    />
  </div>
</template>
