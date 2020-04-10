<script>
import getJiraProjects from '../queries/getJiraProjects.query.graphql';
import JiraImportForm from './jira_import_form.vue';
import JiraImportSetup from './jira_import_setup.vue';

export default {
  name: 'JiraImportApp',
  components: {
    JiraImportForm,
    JiraImportSetup,
  },
  props: {
    isJiraConfigured: {
      type: Boolean,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    setupIllustration: {
      type: String,
      required: true,
    },
  },
  apollo: {
    getJiraImports: {
      query: getJiraProjects,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: data => data.project.jiraImports,
      skip() {
        return !this.isJiraConfigured;
      },
    },
  },
};
</script>

<template>
  <div>
    <jira-import-setup v-if="!isJiraConfigured" :illustration="setupIllustration" />
    <jira-import-form v-else />
  </div>
</template>
