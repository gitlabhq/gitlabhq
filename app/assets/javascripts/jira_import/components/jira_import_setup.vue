<script>
import { GlEmptyState } from '@gitlab/ui';

export default {
  name: 'JiraImportSetup',
  components: {
    GlEmptyState,
  },
  props: {
    illustration: {
      type: String,
      required: true,
    },
    jiraIntegrationPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-empty-state
    :svg-path="illustration"
    title=""
    :description="__('You will first need to set up Jira Integration to use this feature.')"
    :primary-button-text="__('Set up Jira Integration')"
    :primary-button-link="jiraIntegrationPath"
  />
</template>
