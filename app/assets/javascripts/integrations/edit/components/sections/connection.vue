<script>
import { mapState } from 'pinia';
import { INTEGRATION_FORM_TYPE_JIRA, jiraIntegrationAuthFields } from '~/integrations/constants';

import { useIntegrationForm } from '../../store';
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
  emits: ['toggle-integration-active'],
  data() {
    return {
      currentAuthType: null,
    };
  },
  computed: {
    ...mapState(useIntegrationForm, ['currentKey', 'propsSource']),

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
  methods: {
    onChangeAuthType(value) {
      this.currentAuthType = parseInt(value, 10);
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
    <jira-auth-fields
      v-if="isJiraIntegration"
      :key="`${currentKey}-jira-auth-fields`"
      :is-validated="isValidated"
      :fields="jiraAuthFields"
      :current-auth-type="currentAuthType"
      @change-auth-type="onChangeAuthType"
    />
    <dynamic-field
      v-for="field in filteredFields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
      :is-validated="isValidated"
    />
  </div>
</template>
