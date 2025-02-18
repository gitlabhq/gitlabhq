<script>
import { GlBadge } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { integrationFormSectionComponents, billingPlanNames } from '~/integrations/constants';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';

export default {
  name: 'IntegrationFormSection',
  components: {
    GlBadge,
    SettingsSection,
    IntegrationSectionConfiguration: () =>
      import(
        /* webpackChunkName: 'integrationSectionConfiguration' */ '~/integrations/edit/components/sections/configuration.vue'
      ),
    IntegrationSectionConnection: () =>
      import(
        /* webpackChunkName: 'integrationSectionConnection' */ '~/integrations/edit/components/sections/connection.vue'
      ),
    IntegrationSectionJiraIssues: () =>
      import(
        /* webpackChunkName: 'integrationSectionJiraIssues' */ '~/integrations/edit/components/sections/jira_issues.vue'
      ),
    IntegrationSectionJiraIssueCreation: () =>
      import(
        /* webpackChunkName: 'integrationSectionJiraIssues' */ '~/integrations/edit/components/sections/jira_issue_creation.vue'
      ),
    IntegrationSectionJiraTrigger: () =>
      import(
        /* webpackChunkName: 'integrationSectionJiraTrigger' */ '~/integrations/edit/components/sections/jira_trigger.vue'
      ),
    IntegrationSectionTrigger: () =>
      import(
        /* webpackChunkName: 'integrationSectionTrigger' */ '~/integrations/edit/components/sections/trigger.vue'
      ),
    IntegrationSectionAppleAppStore: () =>
      import(
        /* webpackChunkName: 'IntegrationSectionAppleAppStore' */ '~/integrations/edit/components/sections/apple_app_store.vue'
      ),
    IntegrationSectionGooglePlay: () =>
      import(
        /* webpackChunkName: 'IntegrationSectionGooglePlay' */ '~/integrations/edit/components/sections/google_play.vue'
      ),
    IntegrationSectionGoogleArtifactManagement: () =>
      import(
        /* webpackChunkName: 'IntegrationSectionGoogleArtifactManagement' */ 'ee_component/integrations/edit/components/sections/google_artifact_management.vue'
      ),
    IntegrationSectionGoogleCloudIAM: () =>
      import(
        /* webpackChunkName: 'IntegrationSectionGoogleCloudIAM' */ 'ee_component/integrations/edit/components/sections/google_cloud_iam.vue'
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
  computed: {
    ...mapGetters(['propsSource']),
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
