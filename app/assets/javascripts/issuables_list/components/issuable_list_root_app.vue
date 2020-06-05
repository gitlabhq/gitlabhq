<script>
import { GlAlert, GlLabel } from '@gitlab/ui';
import getIssuesListDetailsQuery from '../queries/get_issues_list_details.query.graphql';
import {
  calculateJiraImportLabel,
  isFinished,
  isInProgress,
} from '~/jira_import/utils/jira_import_utils';

export default {
  name: 'IssuableListRoot',
  components: {
    GlAlert,
    GlLabel,
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
    issuesPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isFinishedAlertShowing: true,
      isInProgressAlertShowing: true,
      jiraImport: {},
    };
  },
  apollo: {
    jiraImport: {
      query: getIssuesListDetailsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: ({ project }) => ({
        isInProgress: isInProgress(project.jiraImportStatus),
        isFinished: isFinished(project.jiraImportStatus),
        label: calculateJiraImportLabel(
          project.jiraImports.nodes,
          project.issues.nodes.flatMap(({ labels }) => labels.nodes),
        ),
      }),
      skip() {
        return !this.isJiraConfigured || !this.canEdit;
      },
    },
  },
  computed: {
    labelTarget() {
      return `${this.issuesPath}?label_name[]=${encodeURIComponent(this.jiraImport.label.title)}`;
    },
    shouldShowFinishedAlert() {
      return this.isFinishedAlertShowing && this.jiraImport.isFinished;
    },
    shouldShowInProgressAlert() {
      return this.isInProgressAlertShowing && this.jiraImport.isInProgress;
    },
  },
  methods: {
    hideFinishedAlert() {
      this.isFinishedAlertShowing = false;
    },
    hideInProgressAlert() {
      this.isInProgressAlertShowing = false;
    },
  },
};
</script>

<template>
  <div class="issuable-list-root">
    <gl-alert v-if="shouldShowInProgressAlert" @dismiss="hideInProgressAlert">
      {{ __('Import in progress. Refresh page to see newly added issues.') }}
    </gl-alert>
    <gl-alert v-if="shouldShowFinishedAlert" variant="success" @dismiss="hideFinishedAlert">
      {{ __('Issues successfully imported with the label') }}
      <gl-label
        :background-color="jiraImport.label.color"
        scoped
        size="sm"
        :target="labelTarget"
        :title="jiraImport.label.title"
      />
    </gl-alert>
  </div>
</template>
