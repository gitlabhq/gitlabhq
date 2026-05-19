<script>
import { mapState } from 'pinia';

import { useIntegrationForm } from '../../store';
import JiraIssuesFields from '../jira_issues_fields.vue';

export default {
  name: 'IntegrationSectionJiraIssues',
  components: {
    JiraIssuesFields,
  },
  props: {
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['request-jira-issue-types'],
  computed: {
    ...mapState(useIntegrationForm, ['currentKey', 'propsSource']),
  },
};
</script>

<template>
  <div>
    <jira-issues-fields
      :key="`${currentKey}-jira-issues-fields`"
      v-bind="propsSource.jiraIssuesProps"
      :is-validated="isValidated"
      @request-jira-issue-types="$emit('request-jira-issue-types')"
    />
  </div>
</template>
