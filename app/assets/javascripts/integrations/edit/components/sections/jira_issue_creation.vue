<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';

import JiraIssuesFields from '../jira_issues_fields.vue';

export default {
  name: 'IntegrationSectionJiraIssueCreation',
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
  computed: {
    ...mapGetters(['currentKey', 'propsSource']),
  },
};
</script>

<template>
  <div>
    <jira-issues-fields
      :key="`${currentKey}-jira-issue-creation-fields`"
      v-bind="propsSource.jiraIssuesProps"
      :is-validated="isValidated"
      is-issue-creation
      @request-jira-issue-types="$emit('request-jira-issue-types')"
    />
  </div>
</template>
