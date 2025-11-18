<script>
import { GlTab, GlTabs, GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import Api from '~/api';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { SERVICE_PING_SECURITY_CONFIGURATION_THREAT_MANAGEMENT_VISIT } from '~/tracking/constants';
import { REPORT_TYPE_CONTAINER_SCANNING_FOR_REGISTRY } from '~/vue_shared/security_reports/constants';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY,
  TAB_VULNERABILITY_MANAGEMENT_INDEX,
  i18n,
  SECRET_PUSH_PROTECTION,
  SECRET_DETECTION,
  LICENSE_INFORMATION_SOURCE,
} from '../constants';
import AutoDevOpsAlert from './auto_dev_ops_alert.vue';
import AutoDevOpsEnabledAlert from './auto_dev_ops_enabled_alert.vue';
import FeatureCard from './feature_card.vue';
import PipelineSecretDetectionFeatureCard from './pipeline_secret_detection_feature_card.vue';
import SecretPushProtectionFeatureCard from './secret_push_protection_feature_card.vue';
import TrainingProviderList from './training_provider_list.vue';
import RefTrackingList from './ref_tracking_list.vue';

export default {
  i18n,
  components: {
    ProjectSecurityAttributesList: () =>
      import(
        'ee_component/security_configuration/security_attributes/components/project_attributes_list.vue'
      ),
    AutoDevOpsAlert,
    AutoDevOpsEnabledAlert,
    FeatureCard,
    SecretPushProtectionFeatureCard,
    PipelineSecretDetectionFeatureCard,
    GlAlert,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
    LocalStorageSync,
    SectionLayout,
    BetaBadge,
    UpgradeBanner: () =>
      import('ee_component/security_configuration/components/upgrade_banner.vue'),
    UserCalloutDismisser,
    TrainingProviderList,
    RefTrackingList,
    ContainerScanningForRegistryFeatureCard: () =>
      import(
        'ee_component/security_configuration/components/container_scanning_for_registry_feature_card.vue'
      ),
    PageHeading,
    VulnerabilityArchives: () =>
      import('ee_component/security_configuration/components/vulnerability_archives.vue'),
    LicenseInformationSourceFeatureCard: () =>
      import(
        'ee_component/security_configuration/components/license_information_source_feature_card.vue'
      ),
  },
  directives: { SafeHtml },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectFullPath', 'vulnerabilityTrainingDocsPath', 'canReadAttributes'],
  props: {
    augmentedSecurityFeatures: {
      type: Array,
      required: true,
    },
    gitlabCiPresent: {
      type: Boolean,
      required: false,
      default: false,
    },
    autoDevopsEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    canEnableAutoDevops: {
      type: Boolean,
      required: false,
      default: false,
    },
    gitlabCiHistoryPath: {
      type: String,
      required: false,
      default: '',
    },
    latestPipelinePath: {
      type: String,
      required: false,
      default: '',
    },
    securityTrainingEnabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      autoDevopsEnabledAlertDismissedProjects: [],
      errorMessage: '',
    };
  },
  computed: {
    canUpgrade() {
      return [...this.augmentedSecurityFeatures].some(({ available }) => !available);
    },
    canViewCiHistory() {
      return Boolean(this.gitlabCiPresent && this.gitlabCiHistoryPath);
    },
    shouldShowDevopsAlert() {
      return !this.autoDevopsEnabled && !this.gitlabCiPresent && this.canEnableAutoDevops;
    },
    shouldShowAutoDevopsEnabledAlert() {
      return (
        this.autoDevopsEnabled &&
        !this.autoDevopsEnabledAlertDismissedProjects.includes(this.projectFullPath)
      );
    },
    shouldShowVulnerabilityArchives() {
      return this.glFeatures?.vulnerabilityArchival;
    },
    shouldShowRefsTracking() {
      return this.glFeatures?.vulnerabilitiesAcrossContexts;
    },
    shouldShowSecurityAttributes() {
      return (
        window.gon?.licensed_features?.securityAttributes &&
        this.glFeatures?.securityContextLabels &&
        this.canReadAttributes
      );
    },
    trackedRefsHelpPagePath() {
      // Once the help page content is available, we can use the anchor to link to the specific section
      // See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/578081
      return helpPagePath('user/application_security/vulnerability_report/_index.md');
    },
  },
  methods: {
    getComponentName(feature) {
      if (feature.type === SECRET_PUSH_PROTECTION) {
        return 'secret-push-protection-feature-card';
      }
      if (feature.type === REPORT_TYPE_CONTAINER_SCANNING_FOR_REGISTRY) {
        return 'container-scanning-for-registry-feature-card';
      }
      if (feature.type === SECRET_DETECTION) {
        return 'pipeline-secret-detection-feature-card';
      }
      if (feature.type === LICENSE_INFORMATION_SOURCE) {
        return 'license-information-source-feature-card';
      }

      return 'feature-card';
    },
    dismissAutoDevopsEnabledAlert() {
      const dismissedProjects = new Set(this.autoDevopsEnabledAlertDismissedProjects);
      dismissedProjects.add(this.projectFullPath);
      this.autoDevopsEnabledAlertDismissedProjects = Array.from(dismissedProjects);
    },
    onError(message) {
      this.errorMessage = message;
    },
    dismissAlert() {
      this.errorMessage = '';
    },
    tabChange(value) {
      if (value === TAB_VULNERABILITY_MANAGEMENT_INDEX) {
        Api.trackRedisHllUserEvent(SERVICE_PING_SECURITY_CONFIGURATION_THREAT_MANAGEMENT_VISIT);
      }
    },
  },
  autoDevopsEnabledAlertStorageKey: AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY,
};
</script>

<template>
  <article>
    <gl-alert
      v-if="errorMessage"
      sticky
      class="gl-top-8 gl-z-1"
      data-testid="manage-via-mr-error-alert"
      variant="danger"
      @dismiss="dismissAlert"
    >
      <span v-safe-html="errorMessage"></span>
    </gl-alert>
    <local-storage-sync
      v-model="autoDevopsEnabledAlertDismissedProjects"
      :storage-key="$options.autoDevopsEnabledAlertStorageKey"
    />

    <user-callout-dismisser
      v-if="shouldShowDevopsAlert"
      feature-name="security_configuration_devops_alert"
    >
      <template #default="{ dismiss, shouldShowCallout }">
        <auto-dev-ops-alert v-if="shouldShowCallout" class="gl-mt-3" @dismiss="dismiss" />
      </template>
    </user-callout-dismisser>

    <page-heading :heading="$options.i18n.securityConfiguration" />

    <user-callout-dismisser v-if="canUpgrade" feature-name="security_configuration_upgrade_banner">
      <template #default="{ dismiss, shouldShowCallout }">
        <upgrade-banner v-if="shouldShowCallout" @close="dismiss" />
      </template>
    </user-callout-dismisser>

    <gl-tabs
      content-class="gl-pt-0"
      data-testid="security-configuration-container"
      sync-active-tab-with-query-params
      lazy
      @input="tabChange"
    >
      <gl-tab
        data-testid="security-testing-tab"
        :title="$options.i18n.securityTesting"
        query-param-value="security-testing"
      >
        <auto-dev-ops-enabled-alert
          v-if="shouldShowAutoDevopsEnabledAlert"
          class="gl-mt-3"
          @dismiss="dismissAutoDevopsEnabledAlert"
        />

        <section-layout class="gl-border-b-0" :heading="$options.i18n.securityTesting">
          <template #description>
            <p>
              <span>
                <gl-sprintf
                  v-if="latestPipelinePath"
                  :message="$options.i18n.latestPipelineDescription"
                >
                  <template #link="{ content }">
                    <gl-link :href="latestPipelinePath">{{ content }}</gl-link>
                  </template>
                </gl-sprintf>
              </span>

              {{ $options.i18n.description }}
            </p>
            <p v-if="canViewCiHistory">
              <gl-link data-testid="security-view-history-link" :href="gitlabCiHistoryPath">{{
                $options.i18n.configurationHistory
              }}</gl-link>
            </p>
          </template>

          <template #features>
            <component
              :is="getComponentName(feature)"
              v-for="feature in augmentedSecurityFeatures"
              :id="feature.anchor"
              :key="feature.type"
              data-testid="security-testing-card"
              :feature="feature"
              class="gl-mb-6"
              @error="onError"
            />
          </template>
        </section-layout>
      </gl-tab>
      <gl-tab
        data-testid="vulnerability-management-tab"
        :title="$options.i18n.vulnerabilityManagement"
        query-param-value="vulnerability-management"
      >
        <section-layout
          v-if="shouldShowRefsTracking"
          :heading="__('Refs')"
          data-testid="refs-tracking-section"
        >
          <template #description>
            <p>
              {{
                __(
                  'Track vulnerabilities in up to 16 refs (branches or tags). The default branch is tracked by default on the Security Dashboard and Vulnerability report and cannot be removed.',
                )
              }}
            </p>
            <p>
              {{
                __(
                  'When you remove tracking of a ref, GitLab deletes any vulnerabilities associated with that ref. You have the option to archive them before their deletion.',
                )
              }}
            </p>
            <p>
              <gl-link :href="trackedRefsHelpPagePath">{{
                __('Learn more about vulnerability management on non-default branches and tags.')
              }}</gl-link>
            </p>
          </template>
          <template #features>
            <ref-tracking-list />
          </template>
        </section-layout>
        <section-layout
          :heading="$options.i18n.securityTraining"
          data-testid="security-training-section"
        >
          <template #description>
            <p>
              {{ $options.i18n.securityTrainingDescription }}
            </p>
            <p>
              <gl-link :href="vulnerabilityTrainingDocsPath">{{
                $options.i18n.securityTrainingDoc
              }}</gl-link>
            </p>
          </template>
          <template #features>
            <training-provider-list :security-training-enabled="securityTrainingEnabled" />
          </template>
        </section-layout>
        <vulnerability-archives v-if="shouldShowVulnerabilityArchives" />
      </gl-tab>
      <gl-tab v-if="shouldShowSecurityAttributes" query-param-value="security-attributes">
        <template #title>
          {{ s__('SecurityAttributes|Security attributes') }} <beta-badge class="gl-ml-2" />
        </template>
        <project-security-attributes-list />
      </gl-tab>
    </gl-tabs>
  </article>
</template>
