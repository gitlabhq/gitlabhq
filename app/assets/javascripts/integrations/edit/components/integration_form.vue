<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import JiraIssuesFields from './jira_issues_fields.vue';
import TriggerFields from './trigger_fields.vue';
import DynamicField from './dynamic_field.vue';

export default {
  name: 'IntegrationForm',
  components: {
    ActiveToggle,
    JiraTriggerFields,
    JiraIssuesFields,
    TriggerFields,
    DynamicField,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    activeToggleProps: {
      type: Object,
      required: true,
    },
    showActive: {
      type: Boolean,
      required: true,
    },
    triggerFieldsProps: {
      type: Object,
      required: true,
    },
    jiraIssuesProps: {
      type: Object,
      required: true,
    },
    triggerEvents: {
      type: Array,
      required: false,
      default: () => [],
    },
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    type: {
      type: String,
      required: true,
    },
  },
  computed: {
    isJira() {
      return this.type === 'jira';
    },
    showJiraIssuesFields() {
      return this.isJira && this.glFeatures.jiraIntegration;
    },
  },
};
</script>

<template>
  <div>
    <active-toggle v-if="showActive" v-bind="activeToggleProps" />
    <jira-trigger-fields v-if="isJira" v-bind="triggerFieldsProps" />
    <trigger-fields v-else-if="triggerEvents.length" :events="triggerEvents" :type="type" />
    <dynamic-field v-for="field in fields" :key="field.name" v-bind="field" />
    <jira-issues-fields v-if="showJiraIssuesFields" v-bind="jiraIssuesProps" />
  </div>
</template>
