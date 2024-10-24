<script>
import { GlLoadingIcon, GlModal } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import { mergeUrlParams, queryToObject, visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';

import { unwrapStagesWithNeeds } from '~/ci/pipeline_details/utils/unwrapping_utils';

import ConfirmUnsavedChangesDialog from './components/ui/confirm_unsaved_changes_dialog.vue';
import PipelineEditorEmptyState from './components/ui/pipeline_editor_empty_state.vue';
import PipelineEditorMessages from './components/ui/pipeline_editor_messages.vue';
import {
  COMMIT_SHA_POLL_INTERVAL,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_LINT_UNAVAILABLE,
  EDITOR_APP_VALID_STATUSES,
  LOAD_FAILURE_UNKNOWN,
  STARTER_TEMPLATE_NAME,
  COMMIT_SUCCESS,
  COMMIT_SUCCESS_WITH_REDIRECT,
  DEFAULT_SUCCESS,
} from './constants';
import updateAppStatus from './graphql/mutations/client/update_app_status.mutation.graphql';
import getBlobContent from './graphql/queries/blob_content.query.graphql';
import getCiConfigData from './graphql/queries/ci_config.query.graphql';
import getAppStatus from './graphql/queries/client/app_status.query.graphql';
import getCurrentBranch from './graphql/queries/client/current_branch.query.graphql';
import getTemplate from './graphql/queries/get_starter_template.query.graphql';
import getLatestCommitShaQuery from './graphql/queries/latest_commit_sha.query.graphql';
import PipelineEditorHome from './pipeline_editor_home.vue';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';

export default {
  components: {
    ConfirmUnsavedChangesDialog,
    GlLoadingIcon,
    GlModal,
    PipelineEditorEmptyState,
    PipelineEditorHome,
    PipelineEditorMessages,
  },
  inject: ['ciConfigPath', 'newMergeRequestPath', 'projectFullPath', 'usesExternalConfig'],
  data() {
    return {
      ciConfigData: {},
      currentCiFileContent: '',
      failureType: null,
      failureReasons: [],
      hasBranchLoaded: false,
      initialCiFileContent: '',
      isFetchingCommitSha: false,
      isLintUnavailable: false,
      isNewCiConfigFile: false,
      lastCommittedContent: '',
      shouldSkipStartScreen: false,
      showFailure: false,
      showResetConfirmationModal: false,
      showStartScreen: false,
      starterTemplate: '',
      starterTemplateName: STARTER_TEMPLATE_NAME,
    };
  },
  apollo: {
    initialCiFileContent: {
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      query: getBlobContent,
      // If it's a brand new file, we don't want to fetch the content.
      // Then when the user commits the first time, the query would run
      // to get the initial file content, but we already have it in `lastCommitedContent`
      // so we skip the loading altogether. We also wait for the currentBranch
      // to have been fetched
      skip() {
        return this.shouldSkipBlobContentQuery;
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

          this.isNewCiConfigFile = false;
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
      skip() {
        return this.shouldSkipCiConfigQuery;
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
        if (data?.ciConfig?.status) {
          this.setAppStatus(data.ciConfig.status);
          if (this.isLintUnavailable) {
            this.isLintUnavailable = false;
          }
        }
      },
      error() {
        // We are not using `reportFailure` here because we don't
        // need to bring attention to the linter being down. We let
        // the user work on their file and if they look at their
        // lint status, they will notice that the service is down
        this.isLintUnavailable = true;
      },
      watchLoading(isLoading) {
        if (isLoading) {
          this.setAppStatus(EDITOR_APP_STATUS_LOADING);
        }
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    appStatus: {
      query: getAppStatus,
      update(data) {
        return data.app.status;
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    commitSha: {
      query: getLatestCommitShaQuery,
      skip({ currentBranch }) {
        return !currentBranch;
      },
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.currentBranch,
        };
      },
      update(data) {
        const latestCommitSha = data?.project?.repository?.tree?.lastCommit?.sha;

        if (this.isFetchingCommitSha && latestCommitSha === this.commitSha) {
          this.$apollo.queries.commitSha.startPolling(COMMIT_SHA_POLL_INTERVAL);
          return this.commitSha;
        }

        this.isFetchingCommitSha = false;
        this.$apollo.queries.commitSha.stopPolling();
        return latestCommitSha;
      },
      error() {
        this.reportFailure(LOAD_FAILURE_UNKNOWN);
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    currentBranch: {
      query: getCurrentBranch,
      update(data) {
        return data.workBranches?.current?.name;
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
        this.updateCiConfig(data?.project?.ciTemplate?.content || '');
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
      return !this.hasBranchLoaded || this.$apollo.queries.initialCiFileContent.loading;
    },
    isCiConfigDataLoading() {
      return this.$apollo.queries.ciConfigData.loading;
    },
    isEmpty() {
      return this.currentCiFileContent === '';
    },
    shouldSkipBlobContentQuery() {
      return this.isNewCiConfigFile || this.lastCommittedContent || !this.hasBranchLoaded;
    },
    shouldSkipCiConfigQuery() {
      return !this.currentCiFileContent || !this.commitSha;
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
  success: {
    [COMMIT_SUCCESS]: __('Your changes have been successfully committed.'),
    [COMMIT_SUCCESS_WITH_REDIRECT]: s__(
      'Pipelines|Your changes have been successfully committed. Now redirecting to the new merge request page.',
    ),
    [DEFAULT_SUCCESS]: __('Your action succeeded.'),
  },
  watch: {
    currentBranch: {
      immediate: true,
      handler(branch) {
        // currentBranch is a client query so it starts off undefined. In the index.js,
        // write to the apollo cache. Once that operation is done, we can safely do operations
        // that require the branch to have loaded.
        if (branch) {
          this.hasBranchLoaded = true;
        }
      },
    },
    isEmpty(flag) {
      if (flag) {
        this.setAppStatus(EDITOR_APP_STATUS_EMPTY);
      }
    },
    isLintUnavailable(flag) {
      if (flag) {
        // We cannot set this status directly in the `error`
        // hook otherwise we get an infinite loop caused by apollo.
        this.setAppStatus(EDITOR_APP_STATUS_LINT_UNAVAILABLE);
      }
    },
  },
  mounted() {
    this.loadTemplateFromURL();
    this.checkShouldSkipStartScreen();
  },
  methods: {
    checkShouldSkipStartScreen() {
      const params = queryToObject(window.location.search);
      this.shouldSkipStartScreen = Boolean(params?.add_new_config_file);
    },
    confirmReset() {
      if (this.hasUnsavedChanges) {
        this.showResetConfirmationModal = true;
      }
    },
    hideFailure() {
      this.showFailure = false;
    },
    loadTemplateFromURL() {
      const templateName = queryToObject(window.location.search)?.template;

      if (templateName) {
        this.starterTemplateName = templateName;
        this.setNewEmptyCiConfigFile();
      }
    },
    redirectToNewMergeRequest(sourceBranch, targetBranch) {
      const url = mergeUrlParams(
        {
          [MR_SOURCE_BRANCH]: sourceBranch,
          [MR_TARGET_BRANCH]: targetBranch,
        },
        this.newMergeRequestPath,
      );
      visitUrl(url);
    },
    async refetchContent() {
      this.$apollo.queries.initialCiFileContent.skip = false;
      await this.$apollo.queries.initialCiFileContent.refetch();
    },
    reportFailure(type, reasons = []) {
      this.showFailure = true;
      this.failureType = type;
      this.failureReasons = reasons;
      window.scrollTo({ top: 0, behavior: 'smooth' });
    },
    reportSuccess(type) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
      const { success } = this.$options;
      this.$toast.show(success[type] ?? success[DEFAULT_SUCCESS]);
    },
    resetContent() {
      this.showResetConfirmationModal = false;
      this.currentCiFileContent = this.lastCommittedContent;
    },
    setAppStatus(appStatus) {
      if (EDITOR_APP_VALID_STATUSES.includes(appStatus)) {
        this.$apollo.mutate({
          mutation: updateAppStatus,
          variables: { appStatus },
        });
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
    async updateOnCommit({ type, params = {} }) {
      this.reportSuccess(type);

      if (this.isNewCiConfigFile) {
        this.isNewCiConfigFile = false;
      }

      // Keep track of the latest committed content to know
      // if the user has made changes to the file that are unsaved.
      this.lastCommittedContent = this.currentCiFileContent;

      if (type === COMMIT_SUCCESS_WITH_REDIRECT) {
        const { sourceBranch, targetBranch } = params;
        // This force update does 2 things for us:
        // 1. It make sure `hasUnsavedChanges` is updated so
        // we don't show a modal when the user creates an MR
        // 2. Ensure the commit success banner is visible.
        await this.$forceUpdate();
        this.redirectToNewMergeRequest(sourceBranch, targetBranch);
      }
    },
  },
};
</script>

<template>
  <div class="gl-relative gl-mt-4">
    <gl-loading-icon v-if="isBlobContentLoading" size="lg" class="gl-m-3" />
    <pipeline-editor-empty-state
      v-else-if="showStartScreen || usesExternalConfig"
      @createEmptyConfigFile="setNewEmptyCiConfigFile"
      @refetchContent="refetchContent"
    />
    <div v-else>
      <pipeline-editor-messages
        :failure-type="failureType"
        :failure-reasons="failureReasons"
        :show-failure="showFailure"
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
        v-model="showResetConfirmationModal"
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
