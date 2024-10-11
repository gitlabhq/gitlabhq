<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { last } from 'lodash';
import getJiraImportDetailsQuery from '../queries/get_jira_import_details.query.graphql';
import { isInProgress, extractJiraProjectsOptions } from '../utils/jira_import_utils';
import JiraImportForm from './jira_import_form.vue';
import JiraImportProgress from './jira_import_progress.vue';
import JiraImportSetup from './jira_import_setup.vue';

export default {
  name: 'JiraImportApp',
  components: {
    GlAlert,
    GlLoadingIcon,
    JiraImportForm,
    JiraImportProgress,
    JiraImportSetup,
  },
  props: {
    isJiraConfigured: {
      type: Boolean,
      required: true,
    },
    issuesPath: {
      type: String,
      required: true,
    },
    jiraIntegrationPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
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
  data() {
    return {
      jiraImportDetails: {},
      errorMessage: '',
      showAlert: false,
    };
  },
  apollo: {
    jiraImportDetails: {
      query: getJiraImportDetailsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: ({ project }) => ({
        imports: project.jiraImports.nodes,
        isInProgress: isInProgress(project.jiraImportStatus),
        mostRecentImport: last(project.jiraImports.nodes),
        projects: extractJiraProjectsOptions(project.services.nodes[0].projects.nodes),
      }),
      skip() {
        return !this.isJiraConfigured;
      },
    },
  },
  methods: {
    setAlertMessage(message) {
      this.errorMessage = message;
      this.showAlert = true;
    },
    dismissAlert() {
      this.showAlert = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showAlert" variant="danger" @dismiss="dismissAlert">
      {{ errorMessage }}
    </gl-alert>

    <jira-import-setup
      v-if="!isJiraConfigured"
      :illustration="setupIllustration"
      :jira-integration-path="jiraIntegrationPath"
    />
    <gl-loading-icon v-else-if="$apollo.loading" size="lg" class="mt-3" />
    <jira-import-progress
      v-else-if="jiraImportDetails.isInProgress"
      :illustration="setupIllustration"
      :import-initiator="jiraImportDetails.mostRecentImport.scheduledBy.name"
      :import-project="jiraImportDetails.mostRecentImport.jiraProjectKey"
      :import-time="jiraImportDetails.mostRecentImport.scheduledAt"
      :issues-path="issuesPath"
    />
    <jira-import-form
      v-else
      :issues-path="issuesPath"
      :jira-imports="jiraImportDetails.imports"
      :jira-projects="jiraImportDetails.projects"
      :project-id="projectId"
      :project-path="projectPath"
      @error="setAlertMessage"
    />
  </div>
</template>
