<script>
import { GlLoadingIcon, GlModal } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import { queryToObject } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';

import { unwrapStagesWithNeeds } from '~/pipelines/components/unwrapping_utils';

import ConfirmUnsavedChangesDialog from './components/ui/confirm_unsaved_changes_dialog.vue';
import PipelineEditorEmptyState from './components/ui/pipeline_editor_empty_state.vue';
import PipelineEditorMessages from './components/ui/pipeline_editor_messages.vue';
import {
  COMMIT_SHA_POLL_INTERVAL,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_VALID_STATUSES,
  EDITOR_APP_STATUS_LOADING,
  LOAD_FAILURE_UNKNOWN,
  STARTER_TEMPLATE_NAME,
} from './constants';
import updateAppStatus from './graphql/mutations/client/update_app_status.mutation.graphql';
import getBlobContent from './graphql/queries/blob_content.query.graphql';
import getCiConfigData from './graphql/queries/ci_config.query.graphql';
import getAppStatus from './graphql/queries/client/app_status.query.graphql';
import getCurrentBranch from './graphql/queries/client/current_branch.query.graphql';
import getTemplate from './graphql/queries/get_starter_template.query.graphql';
import getLatestCommitShaQuery from './graphql/queries/latest_commit_sha.query.graphql';
import PipelineEditorHome from './pipeline_editor_home.vue';

export default {
  components: {
    ConfirmUnsavedChangesDialog,
    GlLoadingIcon,
    GlModal,
    PipelineEditorEmptyState,
    PipelineEditorHome,
    PipelineEditorMessages,
  },
  inject: {
    ciConfigPath: {
      default: '',
    },
    projectFullPath: {
      default: '',
    },
  },
  data() {
    return {
      ciConfigData: {},
      currentCiFileContent: '',
      failureType: null,
      failureReasons: [],
      initialCiFileContent: '',
      isFetchingCommitSha: false,
      isNewCiConfigFile: false,
      lastCommittedContent: '',
      shouldSkipStartScreen: false,
      showFailure: false,
      showResetComfirmationModal: false,
      showStartScreen: false,
      showSuccess: false,
      starterTemplate: '',
      starterTemplateName: STARTER_TEMPLATE_NAME,
      successType: null,
    };
  },
  apollo: {
    initialCiFileContent: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query: getBlobContent,
      // If it's a brand new file, we don't want to fetch the content.
      // Then when the user commits the first time, the query would run
      // to get the initial file content, but we already have it in `lastCommitedContent`
      // so we skip the loading altogether.
      skip({ isNewCiConfigFile, lastCommittedContent }) {
        return isNewCiConfigFile || lastCommittedContent;
      },
      variables() {
        return {
          projectPath: this.projectFullPath,
          path: this.ciConfigPath,
          ref: this.currentBranch,
        };
      },
      update(data) {
        return data?.project?.repository?.blobs?.nodes[0]?.rawBlob;
      },
      result({ data }) {
        const nodes = data?.project?.repository?.blobs?.nodes;
        if (!nodes) {
          this.reportFailure(LOAD_FAILURE_UNKNOWN);
        } else {
          const rawBlob = nodes[0]?.rawBlob;
          const fileContent = rawBlob ?? '';

          this.lastCommittedContent = fileContent;
          this.currentCiFileContent = fileContent;

          // If rawBlob is defined and returns a string, it means that there is
          // a CI config file with empty content. If `rawBlob` is not defined
          // at all, it means there was no file found.
          const hasCIFile = rawBlob === '' || fileContent.length > 0;

          if (!fileContent.length) {
            this.setAppStatus(EDITOR_APP_STATUS_EMPTY);
          }

          if (!hasCIFile) {
            if (this.shouldSkipStartScreen) {
              this.setNewEmptyCiConfigFile();
            } else {
              this.showStartScreen = true;
            }
          } else if (fileContent.length) {
            // If the file content is > 0, then we make sure to reset the
            // start screen flag during a refetch
            // e.g. when switching branches
            this.showStartScreen = false;
          }
        }
      },
      error() {
        this.reportFailure(LOAD_FAILURE_UNKNOWN);
      },
      watchLoading(isLoading) {
        if (isLoading) {
          this.setAppStatus(EDITOR_APP_STATUS_LOADING);
        }
      },
    },
    ciConfigData: {
      query: getCiConfigData,
      skip({ currentCiFileContent }) {
        return !currentCiFileContent;
      },
      variables() {
        return {
          projectPath: this.projectFullPath,
          sha: this.commitSha,
          content: this.currentCiFileContent,
        };
      },
      update(data) {
        const { ciConfig } = data || {};
        const stageNodes = ciConfig?.stages?.nodes || [];
        const stages = unwrapStagesWithNeeds(JSON.parse(JSON.stringify(stageNodes)));

        return { ...ciConfig, stages };
      },
      result({ data }) {
        this.setAppStatus(data?.ciConfig?.status);
      },
      error(err) {
        this.reportFailure(LOAD_FAILURE_UNKNOWN, [String(err)]);
      },
      watchLoading(isLoading) {
        if (isLoading) {
          this.setAppStatus(EDITOR_APP_STATUS_LOADING);
        }
      },
    },
    appStatus: {
      query: getAppStatus,
      update(data) {
        return data.app.status;
      },
    },
    commitSha: {
      query: getLatestCommitShaQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.currentBranch,
        };
      },
      update(data) {
        const latestCommitSha = data.project?.repository?.tree?.lastCommit?.sha;

        if (this.isFetchingCommitSha && latestCommitSha === this.commitSha) {
          this.$apollo.queries.commitSha.startPolling(COMMIT_SHA_POLL_INTERVAL);
          return this.commitSha;
        }

        this.isFetchingCommitSha = false;
        this.$apollo.queries.commitSha.stopPolling();
        return latestCommitSha;
      },
    },
    currentBranch: {
      query: getCurrentBranch,
      update(data) {
        return data.workBranches.current.name;
      },
    },
    starterTemplate: {
      query: getTemplate,
      variables() {
        return {
          projectPath: this.projectFullPath,
          templateName: this.starterTemplateName,
        };
      },
      skip({ isNewCiConfigFile }) {
        return !isNewCiConfigFile;
      },
      update(data) {
        return data.project?.ciTemplate?.content || '';
      },
      result({ data }) {
        this.updateCiConfig(data.project?.ciTemplate?.content || '');
      },
      error() {
        this.reportFailure(LOAD_FAILURE_UNKNOWN);
      },
    },
  },
  computed: {
    hasUnsavedChanges() {
      return this.lastCommittedContent !== this.currentCiFileContent;
    },
    isBlobContentLoading() {
      return this.$apollo.queries.initialCiFileContent.loading;
    },
    isCiConfigDataLoading() {
      return this.$apollo.queries.ciConfigData.loading;
    },
    isEmpty() {
      return this.currentCiFileContent === '';
    },
  },
  i18n: {
    resetModal: {
      actionPrimary: {
        text: __('Reset file'),
      },
      actionCancel: {
        text: __('Cancel'),
      },
      body: s__(
        'Pipeline Editor|Are you sure you want to reset the file to its last committed version?',
      ),
      title: __('Discard changes'),
    },
  },
  watch: {
    isEmpty(flag) {
      if (flag) {
        this.setAppStatus(EDITOR_APP_STATUS_EMPTY);
      }
    },
  },
  mounted() {
    this.loadTemplateFromURL();
    this.checkShouldSkipStartScreen();
  },
  methods: {
    hideFailure() {
      this.showFailure = false;
    },
    hideSuccess() {
      this.showSuccess = false;
    },
    confirmReset() {
      if (this.hasUnsavedChanges) {
        this.showResetComfirmationModal = true;
      }
    },
    async refetchContent() {
      this.$apollo.queries.initialCiFileContent.skip = false;
      await this.$apollo.queries.initialCiFileContent.refetch();
    },
    reportFailure(type, reasons = []) {
      const isCurrentFailure = this.failureType === type && this.failureReasons[0] === reasons[0];

      if (!isCurrentFailure) {
        this.showFailure = true;
        this.failureType = type;
        this.failureReasons = reasons;
        window.scrollTo({ top: 0, behavior: 'smooth' });
      }
    },
    reportSuccess(type) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
      this.showSuccess = true;
      this.successType = type;
    },
    resetContent() {
      this.showResetComfirmationModal = false;
      this.currentCiFileContent = this.lastCommittedContent;
    },
    setAppStatus(appStatus) {
      if (EDITOR_APP_VALID_STATUSES.includes(appStatus)) {
        this.$apollo.mutate({ mutation: updateAppStatus, variables: { appStatus } });
      }
    },
    setNewEmptyCiConfigFile() {
      this.isNewCiConfigFile = true;
      this.showStartScreen = false;
    },
    showErrorAlert({ type, reasons = [] }) {
      this.reportFailure(type, reasons);
    },
    updateCiConfig(ciFileContent) {
      this.currentCiFileContent = ciFileContent;
    },
    updateCommitSha() {
      this.isFetchingCommitSha = true;
      this.$apollo.queries.commitSha.refetch();
    },
    updateOnCommit({ type }) {
      this.reportSuccess(type);

      if (this.isNewCiConfigFile) {
        this.isNewCiConfigFile = false;
      }

      // Keep track of the latest committed content to know
      // if the user has made changes to the file that are unsaved.
      this.lastCommittedContent = this.currentCiFileContent;
    },
    loadTemplateFromURL() {
      const templateName = queryToObject(window.location.search)?.template;

      if (templateName) {
        this.starterTemplateName = templateName;
        this.setNewEmptyCiConfigFile();
      }
    },
    checkShouldSkipStartScreen() {
      const params = queryToObject(window.location.search);
      this.shouldSkipStartScreen = Boolean(params?.add_new_config_file);
    },
  },
};
</script>

<template>
  <div class="gl-mt-4 gl-relative">
    <gl-loading-icon v-if="isBlobContentLoading" size="lg" class="gl-m-3" />
    <pipeline-editor-empty-state
      v-else-if="showStartScreen"
      @createEmptyConfigFile="setNewEmptyCiConfigFile"
      @refetchContent="refetchContent"
    />
    <div v-else>
      <pipeline-editor-messages
        :failure-type="failureType"
        :failure-reasons="failureReasons"
        :show-failure="showFailure"
        :show-success="showSuccess"
        :success-type="successType"
        @hide-success="hideSuccess"
        @hide-failure="hideFailure"
      />
      <pipeline-editor-home
        :ci-config-data="ciConfigData"
        :ci-file-content="currentCiFileContent"
        :commit-sha="commitSha"
        :has-unsaved-changes="hasUnsavedChanges"
        :is-new-ci-config-file="isNewCiConfigFile"
        @commit="updateOnCommit"
        @resetContent="confirmReset"
        @showError="showErrorAlert"
        @refetchContent="refetchContent"
        @updateCiConfig="updateCiConfig"
        @updateCommitSha="updateCommitSha"
      />
      <gl-modal
        v-model="showResetComfirmationModal"
        modal-id="reset-content"
        :title="$options.i18n.resetModal.title"
        :action-cancel="$options.i18n.resetModal.actionCancel"
        :action-primary="$options.i18n.resetModal.actionPrimary"
        @primary="resetContent"
      >
        {{ $options.i18n.resetModal.body }}
      </gl-modal>
      <confirm-unsaved-changes-dialog :has-unsaved-changes="hasUnsavedChanges" />
    </div>
  </div>
</template>
