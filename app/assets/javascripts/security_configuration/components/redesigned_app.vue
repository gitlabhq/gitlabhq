<script>
import { GlTab, GlTabs, GlSprintf, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import AutoDevOpsAlert from './auto_dev_ops_alert.vue';
import FeatureCard from './feature_card.vue';
import SectionLayout from './section_layout.vue';
import UpgradeBanner from './upgrade_banner.vue';

export const i18n = {
  compliance: s__('SecurityConfiguration|Compliance'),
  configurationHistory: s__('SecurityConfiguration|Configuration history'),
  securityTesting: s__('SecurityConfiguration|Security testing'),
  latestPipelineDescription: s__(
    `SecurityConfiguration|The status of the tools only applies to the
     default branch and is based on the %{linkStart}latest pipeline%{linkEnd}.`,
  ),
  description: s__(
    `SecurityConfiguration|Once you've enabled a scan for the default branch,
     any subsequent feature branch you create will include the scan.`,
  ),
  securityConfiguration: __('Security Configuration'),
};

export default {
  i18n,
  components: {
    GlTab,
    GlLink,
    GlTabs,
    GlSprintf,
    FeatureCard,
    SectionLayout,
    UpgradeBanner,
    AutoDevOpsAlert,
    UserCalloutDismisser,
  },
  props: {
    augmentedSecurityFeatures: {
      type: Array,
      required: true,
    },
    augmentedComplianceFeatures: {
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
  },
  computed: {
    canUpgrade() {
      return [...this.augmentedSecurityFeatures, ...this.augmentedComplianceFeatures].some(
        ({ available }) => !available,
      );
    },
    canViewCiHistory() {
      return Boolean(this.gitlabCiPresent && this.gitlabCiHistoryPath);
    },
    shouldShowDevopsAlert() {
      return !this.autoDevopsEnabled && !this.gitlabCiPresent && this.canEnableAutoDevops;
    },
  },
};
</script>

<template>
  <article>
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

    <gl-tabs content-class="gl-pt-6">
      <gl-tab data-testid="security-testing-tab" :title="$options.i18n.securityTesting">
        <section-layout :heading="$options.i18n.securityTesting">
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
              <gl-link data-testid="security-view-history-link" :href="gitlabCiHistoryPath">{{
                $options.i18n.configurationHistory
              }}</gl-link>
            </p>
          </template>

          <template #features>
            <feature-card
              v-for="feature in augmentedSecurityFeatures"
              :key="feature.type"
              data-testid="security-testing-card"
              :feature="feature"
              class="gl-mb-6"
            />
          </template>
        </section-layout>
      </gl-tab>
      <gl-tab data-testid="compliance-testing-tab" :title="$options.i18n.compliance">
        <section-layout :heading="$options.i18n.compliance">
          <template #description>
            <p>
              <span data-testid="latest-pipeline-info-compliance">
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
              <gl-link data-testid="compliance-view-history-link" :href="gitlabCiHistoryPath">{{
                $options.i18n.configurationHistory
              }}</gl-link>
            </p>
          </template>
          <template #features>
            <feature-card
              v-for="feature in augmentedComplianceFeatures"
              :key="feature.type"
              :feature="feature"
              class="gl-mb-6"
            />
          </template>
        </section-layout>
      </gl-tab>
    </gl-tabs>
  </article>
</template>
