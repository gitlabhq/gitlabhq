<script>
import { GlAlert, GlLabel } from '@gitlab/ui';
import { last } from 'lodash';
import {
  calculateJiraImportLabel,
  isInProgress,
  setFinishedAlertHideMap,
  shouldShowFinishedAlert,
} from '~/jira_import/utils/jira_import_utils';
import { n__ } from '~/locale';
import getIssuesListDetailsQuery from '../queries/get_issues_list_details.query.graphql';

export default {
  name: 'JiraIssuesImportStatus',
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
      update: ({ project }) => {
        const label = calculateJiraImportLabel(
          project.jiraImports.nodes,
          project.issues.nodes.flatMap(({ labels }) => labels.nodes),
        );
        return {
          importedIssuesCount: last(project.jiraImports.nodes)?.importedIssuesCount,
          label,
          shouldShowFinishedAlert: shouldShowFinishedAlert(label.title, project.jiraImportStatus),
          shouldShowInProgressAlert: isInProgress(project.jiraImportStatus),
        };
      },
    },
  },
  computed: {
    finishedMessage() {
      return n__(
        '%d issue successfully imported with the label',
        '%d issues successfully imported with the label',
        this.jiraImport.importedIssuesCount,
      );
    },
    labelTarget() {
      return `${this.issuesPath}?label_name[]=${encodeURIComponent(this.jiraImport.label.title)}`;
    },
    shouldRender() {
      return this.jiraImport.shouldShowInProgressAlert || this.jiraImport.shouldShowFinishedAlert;
    },
  },
  methods: {
    hideFinishedAlert() {
      setFinishedAlertHideMap(this.jiraImport.label.title);
      this.jiraImport.shouldShowFinishedAlert = false;
    },
    hideInProgressAlert() {
      this.jiraImport.shouldShowInProgressAlert = false;
    },
  },
};
</script>

<template>
  <div v-if="shouldRender" class="gl-my-5">
    <gl-alert v-if="jiraImport.shouldShowInProgressAlert" @dismiss="hideInProgressAlert">
      {{ __('Import in progress. Refresh page to see newly added issues.') }}
    </gl-alert>

    <gl-alert
      v-else-if="jiraImport.shouldShowFinishedAlert"
      variant="success"
      @dismiss="hideFinishedAlert"
    >
      {{ finishedMessage }}
      <gl-label
        :background-color="jiraImport.label.color"
        scoped
        :target="labelTarget"
        :title="jiraImport.label.title"
      />
    </gl-alert>
  </div>
</template>
