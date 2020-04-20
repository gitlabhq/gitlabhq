<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
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
        import: project.jiraImports.nodes[0],
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

            store.writeQuery({
              query: getJiraImportDetailsQuery,
              variables: {
                fullPath: this.projectPath,
              },
              data: {
                project: {
                  jiraImportStatus: IMPORT_STATE.SCHEDULED,
                  jiraImports: {
                    nodes: [data.jiraImportStart.jiraImport],
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

    <jira-import-setup v-if="!isJiraConfigured" :illustration="setupIllustration" />
    <gl-loading-icon v-else-if="$apollo.loading" size="md" class="mt-3" />
    <jira-import-progress
      v-else-if="isImportInProgress"
      :illustration="inProgressIllustration"
      :import-initiator="jiraImportDetails.import.scheduledBy.name"
      :import-project="jiraImportDetails.import.jiraProjectKey"
      :import-time="jiraImportDetails.import.scheduledAt"
      :issues-path="issuesPath"
    />
    <jira-import-form
      v-else
      :issues-path="issuesPath"
      :jira-projects="jiraProjectsOptions"
      @initiateJiraImport="initiateJiraImport"
    />
  </div>
</template>
