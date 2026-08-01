<script>
import { defineAsyncComponent } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { mapState } from 'pinia';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  integrationFormSectionComponents,
  billingPlanNames,
} from 'ee_else_ce/integrations/constants';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import { useIntegrationForm } from '../../store';

export default {
  name: 'IntegrationFormSection',
  components: {
    GlBadge,
    SettingsSection,
    IntegrationSectionConfiguration: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionConfiguration' */ '~/integrations/edit/components/sections/configuration.vue'
        ),
    ),
    IntegrationSectionConnection: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionConnection' */ '~/integrations/edit/components/sections/connection.vue'
        ),
    ),
    IntegrationSectionJiraIssues: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionJiraIssues' */ '~/integrations/edit/components/sections/jira_issues.vue'
        ),
    ),
    IntegrationSectionJiraIssueCreation: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionJiraIssues' */ '~/integrations/edit/components/sections/jira_issue_creation.vue'
        ),
    ),
    IntegrationSectionJiraTrigger: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionJiraTrigger' */ '~/integrations/edit/components/sections/jira_trigger.vue'
        ),
    ),
    IntegrationSectionJiraVerification: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionJiraVerification' */ 'ee_component/integrations/edit/components/sections/jira_verification.vue'
        ),
    ),
    IntegrationSectionTrigger: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'integrationSectionTrigger' */ '~/integrations/edit/components/sections/trigger.vue'
        ),
    ),
    IntegrationSectionAppleAppStore: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'IntegrationSectionAppleAppStore' */ '~/integrations/edit/components/sections/apple_app_store.vue'
        ),
    ),
    IntegrationSectionGooglePlay: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'IntegrationSectionGooglePlay' */ '~/integrations/edit/components/sections/google_play.vue'
        ),
    ),
    IntegrationSectionGoogleArtifactManagement: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'IntegrationSectionGoogleArtifactManagement' */ 'ee_component/integrations/edit/components/sections/google_artifact_management.vue'
        ),
    ),
    IntegrationSectionGoogleCloudIAM: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'IntegrationSectionGoogleCloudIAM' */ 'ee_component/integrations/edit/components/sections/google_cloud_iam.vue'
        ),
    ),
    IntegrationSectionAmazonQ: defineAsyncComponent(
      () =>
        import(
          /* webpackChunkName: 'IntegrationSectionAmazonQ' */ 'ee_component/integrations/edit/components/sections/amazon_q.vue'
        ),
    ),
  },
  directives: {
    SafeHtml,
  },
  props: {
    section: {
      type: Object,
      required: true,
    },
    isValidated: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['request-jira-issue-types', 'toggle-integration-active'],
  computed: {
    ...mapState(useIntegrationForm, ['propsSource']),
  },
  methods: {
    fieldsForSection(section) {
      return this.propsSource.fields.filter((field) => field.section === section.type);
    },
  },
  billingPlanNames,
  integrationFormSectionComponents,
};
</script>
<template>
  <settings-section
    heading-classes="gl-inline-flex gl-flex-wrap gl-gap-x-3 gl-gap-y-2 gl-items-center"
  >
    <template v-if="section.title" #heading>
      {{ section.title }}
      <gl-badge
        v-if="section.plan"
        :href="propsSource.aboutPricingUrl"
        target="_blank"
        rel="noopener noreferrer"
        variant="tier"
        icon="license"
      >
        {{ $options.billingPlanNames[section.plan] }}
      </gl-badge>
    </template>

    <template #description>
      <span v-safe-html="section.description"></span>
    </template>

    <component
      :is="$options.integrationFormSectionComponents[section.type]"
      :fields="fieldsForSection(section)"
      :is-validated="isValidated"
      @toggle-integration-active="$emit('toggle-integration-active', $event)"
      @request-jira-issue-types="$emit('request-jira-issue-types', $event)"
    />
  </settings-section>
</template>
