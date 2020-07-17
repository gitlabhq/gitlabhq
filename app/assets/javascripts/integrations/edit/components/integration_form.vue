<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import OverrideDropdown from './override_dropdown.vue';
import ActiveToggle from './active_toggle.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import JiraIssuesFields from './jira_issues_fields.vue';
import TriggerFields from './trigger_fields.vue';
import DynamicField from './dynamic_field.vue';

export default {
  name: 'IntegrationForm',
  components: {
    OverrideDropdown,
    ActiveToggle,
    JiraTriggerFields,
    JiraIssuesFields,
    TriggerFields,
    DynamicField,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentKey', 'propsSource']),
    ...mapState(['adminState', 'override']),
    isJira() {
      return this.propsSource.type === 'jira';
    },
    showJiraIssuesFields() {
      return this.isJira && this.glFeatures.jiraIssuesIntegration;
    },
  },
  methods: {
    ...mapActions(['setOverride']),
  },
};
</script>

<template>
  <div>
    <override-dropdown
      v-if="adminState !== null"
      :inherit-from-id="adminState.id"
      :override="override"
      @change="setOverride"
    />
    <active-toggle
      v-if="propsSource.showActive"
      :key="`${currentKey}-active-toggle`"
      v-bind="propsSource.activeToggleProps"
    />
    <jira-trigger-fields
      v-if="isJira"
      :key="`${currentKey}-jira-trigger-fields`"
      v-bind="propsSource.triggerFieldsProps"
    />
    <trigger-fields
      v-else-if="propsSource.triggerEvents.length"
      :key="`${currentKey}-trigger-fields`"
      :events="propsSource.triggerEvents"
      :type="propsSource.type"
    />
    <dynamic-field
      v-for="field in propsSource.fields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
    />
    <jira-issues-fields
      v-if="showJiraIssuesFields"
      :key="`${currentKey}-jira-issues-fields`"
      v-bind="propsSource.jiraIssuesProps"
    />
  </div>
</template>
