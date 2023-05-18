<script>
import { GlTab, GlTabs, GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import AutoDevOpsAlert from './auto_dev_ops_alert.vue';
import AutoDevOpsEnabledAlert from './auto_dev_ops_enabled_alert.vue';
import { AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY } from './constants';
import FeatureCard from './feature_card.vue';
import TrainingProviderList from './training_provider_list.vue';

export const i18n = {
  configurationHistory: s__('SecurityConfiguration|Configuration history'),
  securityTesting: s__('SecurityConfiguration|Security testing'),
  latestPipelineDescription: s__(
    `SecurityConfiguration|The status of the tools only applies to the
     default branch and is based on the %{linkStart}latest pipeline%{linkEnd}.`,
  ),
  description: s__(
    `SecurityConfiguration|Once you've enabled a scan for the default branch,
     any subsequent feature branch you create will include the scan. An enabled
     scanner will not be reflected as such until the pipeline has been
     successfully executed and it has generated valid artifacts.`,
  ),
  securityConfiguration: __('Security configuration'),
  vulnerabilityManagement: s__('SecurityConfiguration|Vulnerability Management'),
  securityTraining: s__('SecurityConfiguration|Security training'),
  securityTrainingDescription: s__(
    'SecurityConfiguration|Enable security training to help your developers learn how to fix vulnerabilities. Developers can view security training from selected educational providers, relevant to the detected vulnerability.',
  ),
  securityTrainingDoc: s__('SecurityConfiguration|Learn more about vulnerability training'),
};

export default {
  i18n,
  components: {
    AutoDevOpsAlert,
    AutoDevOpsEnabledAlert,
    FeatureCard,
    GlAlert,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
    LocalStorageSync,
    SectionLayout,
    UpgradeBanner: () =>
      import('ee_component/security_configuration/components/upgrade_banner.vue'),
    UserCalloutDismisser,
    TrainingProviderList,
  },
  directives: { SafeHtml },
  inject: ['projectFullPath', 'vulnerabilityTrainingDocsPath'],
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
  },
  methods: {
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
  },
  autoDevopsEnabledAlertStorageKey: AUTO_DEVOPS_ENABLED_ALERT_DISMISSED_STORAGE_KEY,
};
</script>

<template>
  <article>
    <gl-alert
      v-if="errorMessage"
      sticky
      class="gl-top-8 gl-z-index-1"
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
    <header>
      <h1 class="gl-font-size-h1">{{ $options.i18n.securityConfiguration }}</h1>
    </header>
    <user-callout-dismisser v-if="canUpgrade" feature-name="security_configuration_upgrade_banner">
      <template #default="{ dismiss, shouldShowCallout }">
        <upgrade-banner v-if="shouldShowCallout" @close="dismiss" />
      </template>
    </user-callout-dismisser>

    <gl-tabs
      content-class="gl-pt-0"
      data-qa-selector="security_configuration_container"
      sync-active-tab-with-query-params
      lazy
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
              <span data-testid="latest-pipeline-info-security">
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
              <gl-link
                data-testid="security-view-history-link"
                data-qa-selector="security_configuration_history_link"
                :href="gitlabCiHistoryPath"
                >{{ $options.i18n.configurationHistory }}</gl-link
              >
            </p>
          </template>

          <template #features>
            <feature-card
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
        <section-layout :heading="$options.i18n.securityTraining">
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
      </gl-tab>
    </gl-tabs>
  </article>
</template>
