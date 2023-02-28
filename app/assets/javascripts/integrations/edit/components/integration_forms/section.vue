<script>
import { GlBadge } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { integrationFormSectionComponents, billingPlanNames } from '~/integrations/constants';

export default {
  name: 'IntegrationFormSection',
  components: {
    GlBadge,
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
  <section class="gl-lg-display-flex">
    <div class="gl-flex-basis-third gl-mr-4">
      <h4 class="gl-mt-0">
        {{ section.title
        }}<gl-badge
          v-if="section.plan"
          :href="propsSource.aboutPricingUrl"
          target="_blank"
          rel="noopener noreferrer"
          variant="tier"
          icon="license"
          class="gl-ml-3"
        >
          {{ $options.billingPlanNames[section.plan] }}
        </gl-badge>
      </h4>
      <p v-safe-html="section.description"></p>
    </div>

    <div
      v-if="$options.integrationFormSectionComponents[section.type]"
      class="gl-flex-basis-two-thirds"
    >
      <component
        :is="$options.integrationFormSectionComponents[section.type]"
        :fields="fieldsForSection(section)"
        :is-validated="isValidated"
        @toggle-integration-active="$emit('toggle-integration-active', $event)"
        @request-jira-issue-types="$emit('request-jira-issue-types', $event)"
      />
    </div>
  </section>
</template>
