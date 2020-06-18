<script>
import { GlAlert, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { last } from 'lodash';
import { __ } from '~/locale';
import getJiraImportDetailsQuery from '../queries/get_jira_import_details.query.graphql';
import initiateJiraImportMutation from '../queries/initiate_jira_import.mutation.graphql';
import { addInProgressImportToStore } from '../utils/cache_update';
import { isInProgress, extractJiraProjectsOptions } from '../utils/jira_import_utils';
import JiraImportForm from './jira_import_form.vue';
import JiraImportProgress from './jira_import_progress.vue';
import JiraImportSetup from './jira_import_setup.vue';

export default {
  name: 'JiraImportApp',
  components: {
    GlAlert,
    GlLoadingIcon,
    GlSprintf,
    JiraImportForm,
    JiraImportProgress,
    JiraImportSetup,
  },
  props: {
    inProgressIllustration: {
      type: String,
      required: true,
    },
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
      selectedProject: undefined,
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
  computed: {
    numberOfPreviousImports() {
      return this.jiraImportDetails.imports?.reduce?.(
        (acc, jiraProject) => (jiraProject.jiraProjectKey === this.selectedProject ? acc + 1 : acc),
        0,
      );
    },
    hasPreviousImports() {
      return this.numberOfPreviousImports > 0;
    },
    importLabel() {
      return this.selectedProject
        ? `jira-import::${this.selectedProject}-${this.numberOfPreviousImports + 1}`
        : 'jira-import::KEY-1';
    },
  },
  methods: {
    initiateJiraImport(project) {
      this.$apollo
        .mutate({
          mutation: initiateJiraImportMutation,
          variables: {
            input: {
              projectPath: this.projectPath,
              jiraProjectKey: project,
            },
          },
          update: (store, { data }) =>
            addInProgressImportToStore(store, data.jiraImportStart, this.projectPath),
        })
        .then(({ data }) => {
          if (data.jiraImportStart.errors.length) {
            this.setAlertMessage(data.jiraImportStart.errors.join('. '));
          } else {
            this.selectedProject = undefined;
          }
        })
        .catch(() => this.setAlertMessage(__('There was an error importing the Jira project.')));
    },
    setAlertMessage(message) {
      this.errorMessage = message;
      this.showAlert = true;
    },
    dismissAlert() {
      this.showAlert = false;
    },
  },
  previousImportsMessage: __(
    'You have imported from this project %{numberOfPreviousImports} times before. Each new import will create duplicate issues.',
  ),
};
</script>

<template>
  <div>
    <gl-alert v-if="showAlert" variant="danger" @dismiss="dismissAlert">
      {{ errorMessage }}
    </gl-alert>
    <gl-alert v-if="hasPreviousImports" variant="warning" :dismissible="false">
      <gl-sprintf :message="$options.previousImportsMessage">
        <template #numberOfPreviousImports>{{ numberOfPreviousImports }}</template>
      </gl-sprintf>
    </gl-alert>

    <jira-import-setup
      v-if="!isJiraConfigured"
      :illustration="setupIllustration"
      :jira-integration-path="jiraIntegrationPath"
    />
    <gl-loading-icon v-else-if="$apollo.loading" size="md" class="mt-3" />
    <jira-import-progress
      v-else-if="jiraImportDetails.isInProgress"
      :illustration="inProgressIllustration"
      :import-initiator="jiraImportDetails.mostRecentImport.scheduledBy.name"
      :import-project="jiraImportDetails.mostRecentImport.jiraProjectKey"
      :import-time="jiraImportDetails.mostRecentImport.scheduledAt"
      :issues-path="issuesPath"
    />
    <jira-import-form
      v-else
      v-model="selectedProject"
      :import-label="importLabel"
      :issues-path="issuesPath"
      :jira-projects="jiraImportDetails.projects"
      @initiateJiraImport="initiateJiraImport"
    />
  </div>
</template>
