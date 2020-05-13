<script>
import { GlAlert } from '@gitlab/ui';
import getJiraImportDetailsQuery from '~/jira_import/queries/get_jira_import_details.query.graphql';
import { isInProgress } from '~/jira_import/utils';

export default {
  name: 'IssuableListRoot',
  components: {
    GlAlert,
  },
  props: {
    canEdit: {
      type: Boolean,
      required: true,
    },
    isJiraConfigured: {
      type: Boolean,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isAlertShowing: true,
    };
  },
  apollo: {
    jiraImport: {
      query: getJiraImportDetailsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: ({ project }) => ({
        isInProgress: isInProgress(project.jiraImportStatus),
      }),
      skip() {
        return !this.isJiraConfigured || !this.canEdit;
      },
    },
  },
  computed: {
    shouldShowAlert() {
      return this.isAlertShowing && this.jiraImport?.isInProgress;
    },
  },
  methods: {
    hideAlert() {
      this.isAlertShowing = false;
    },
  },
};
</script>

<template>
  <gl-alert v-if="shouldShowAlert" @dismiss="hideAlert">
    {{ __('Import in progress. Refresh page to see newly added issues.') }}
  </gl-alert>
</template>
