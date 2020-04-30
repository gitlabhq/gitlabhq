<script>
import { GlAlert, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import last from 'lodash/last';
import { __ } from '~/locale';
import getJiraImportDetailsQuery from '../queries/get_jira_import_details.query.graphql';
import initiateJiraImportMutation from '../queries/initiate_jira_import.mutation.graphql';
import { IMPORT_STATE, isInProgress } from '../utils';
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
    isJiraConfigured: {
      type: Boolean,
      required: true,
    },
    inProgressIllustration: {
      type: String,
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
    jiraProjects: {
      type: Array,
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
        status: project.jiraImportStatus,
        imports: project.jiraImports.nodes,
      }),
      skip() {
        return !this.isJiraConfigured;
      },
    },
  },
  computed: {
    isImportInProgress() {
      return isInProgress(this.jiraImportDetails?.status);
    },
    jiraProjectsOptions() {
      return this.jiraProjects.map(([text, value]) => ({ text, value }));
    },
    mostRecentImport() {
      // The backend returns JiraImports ordered by created_at asc in app/models/project.rb
      return last(this.jiraImportDetails?.imports);
    },
    numberOfPreviousImportsForProject() {
      return this.jiraImportDetails?.imports?.reduce?.(
        (acc, jiraProject) => (jiraProject.jiraProjectKey === this.selectedProject ? acc + 1 : acc),
        0,
      );
    },
    importLabel() {
      return this.selectedProject
        ? `jira-import::${this.selectedProject}-${this.numberOfPreviousImportsForProject + 1}`
        : 'jira-import::KEY-1';
    },
    hasPreviousImports() {
      return this.numberOfPreviousImportsForProject > 0;
    },
  },
  methods: {
    dismissAlert() {
      this.showAlert = false;
    },
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
          update: (store, { data }) => {
            if (data.jiraImportStart.errors.length) {
              return;
            }

            const cacheData = store.readQuery({
              query: getJiraImportDetailsQuery,
              variables: {
                fullPath: this.projectPath,
              },
            });

            store.writeQuery({
              query: getJiraImportDetailsQuery,
              variables: {
                fullPath: this.projectPath,
              },
              data: {
                project: {
                  jiraImportStatus: IMPORT_STATE.SCHEDULED,
                  jiraImports: {
                    nodes: [
                      ...cacheData.project.jiraImports.nodes,
                      data.jiraImportStart.jiraImport,
                    ],
                    __typename: 'JiraImportConnection',
                  },
                  // eslint-disable-next-line @gitlab/require-i18n-strings
                  __typename: 'Project',
                },
              },
            });
          },
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
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showAlert" variant="danger" @dismiss="dismissAlert">
      {{ errorMessage }}
    </gl-alert>
    <gl-alert v-if="hasPreviousImports" variant="warning" :dismissible="false">
      <gl-sprintf
        :message="
          __(
            'You have imported from this project %{numberOfPreviousImportsForProject} times before. Each new import will create duplicate issues.',
          )
        "
      >
        <template #numberOfPreviousImportsForProject>{{
          numberOfPreviousImportsForProject
        }}</template>
      </gl-sprintf>
    </gl-alert>

    <jira-import-setup
      v-if="!isJiraConfigured"
      :illustration="setupIllustration"
      :jira-integration-path="jiraIntegrationPath"
    />
    <gl-loading-icon v-else-if="$apollo.loading" size="md" class="mt-3" />
    <jira-import-progress
      v-else-if="isImportInProgress"
      :illustration="inProgressIllustration"
      :import-initiator="mostRecentImport.scheduledBy.name"
      :import-project="mostRecentImport.jiraProjectKey"
      :import-time="mostRecentImport.scheduledAt"
      :issues-path="issuesPath"
    />
    <jira-import-form
      v-else
      v-model="selectedProject"
      :import-label="importLabel"
      :issues-path="issuesPath"
      :jira-projects="jiraProjectsOptions"
      @initiateJiraImport="initiateJiraImport"
    />
  </div>
</template>
