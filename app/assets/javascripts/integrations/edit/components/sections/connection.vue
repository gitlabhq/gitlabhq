<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { INTEGRATION_FORM_TYPE_JIRA, jiraIntegrationAuthFields } from '~/integrations/constants';

import ActiveCheckbox from '../active_checkbox.vue';
import DynamicField from '../dynamic_field.vue';

export default {
  name: 'IntegrationSectionConnection',
  components: {
    ActiveCheckbox,
    DynamicField,
    JiraAuthFields: () =>
      import(
        /* webpackChunkName: 'integrationJiraAuthFields' */ '~/integrations/edit/components/jira_auth_fields.vue'
      ),
  },
  props: {
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['currentKey', 'propsSource']),

    isJiraIntegration() {
      return this.propsSource.type === INTEGRATION_FORM_TYPE_JIRA;
    },

    filteredFields() {
      if (!this.isJiraIntegration) {
        return this.fields;
      }

      return this.fields.filter(
        (field) => !Object.values(jiraIntegrationAuthFields).includes(field.name),
      );
    },
    jiraAuthFields() {
      if (!this.isJiraIntegration) {
        return [];
      }

      return this.fields.filter((field) =>
        Object.values(jiraIntegrationAuthFields).includes(field.name),
      );
    },
  },
};
</script>

<template>
  <div>
    <active-checkbox
      v-if="propsSource.manualActivation"
      :key="`${currentKey}-active-checkbox`"
      @toggle-integration-active="$emit('toggle-integration-active', $event)"
    />
    <dynamic-field
      v-for="field in filteredFields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
      :is-validated="isValidated"
    />
    <jira-auth-fields
      v-if="isJiraIntegration"
      :key="`${currentKey}-jira-auth-fields`"
      :is-validated="isValidated"
      :fields="jiraAuthFields"
    />
  </div>
</template>
