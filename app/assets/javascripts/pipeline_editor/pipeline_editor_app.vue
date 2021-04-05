<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import httpStatusCodes from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';

import { unwrapStagesWithNeeds } from '~/pipelines/components/unwrapping_utils';
import ConfirmUnsavedChangesDialog from './components/ui/confirm_unsaved_changes_dialog.vue';
import PipelineEditorEmptyState from './components/ui/pipeline_editor_empty_state.vue';
import {
  COMMIT_FAILURE,
  COMMIT_SUCCESS,
  DEFAULT_FAILURE,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_ERROR,
  EDITOR_APP_STATUS_LOADING,
  LOAD_FAILURE_UNKNOWN,
} from './constants';
import getBlobContent from './graphql/queries/blob_content.graphql';
import getCiConfigData from './graphql/queries/ci_config.graphql';
import getAppStatus from './graphql/queries/client/app_status.graphql';
import getCurrentBranch from './graphql/queries/client/current_branch.graphql';
import getIsNewCiConfigFile from './graphql/queries/client/is_new_ci_config_file.graphql';
import PipelineEditorHome from './pipeline_editor_home.vue';

export default {
  components: {
    ConfirmUnsavedChangesDialog,
    GlAlert,
    GlLoadingIcon,
    PipelineEditorEmptyState,
    PipelineEditorHome,
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
      failureType: null,
      failureReasons: [],
      showStartScreen: false,
      isNewCiConfigFile: false,
      initialCiFileContent: '',
      lastCommittedContent: '',
      currentCiFileContent: '',
      showFailureAlert: false,
      showSuccessAlert: false,
      successType: null,
    };
  },
  apollo: {
    initialCiFileContent: {
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
        return data?.blobContent?.rawData;
      },
      result({ data }) {
        const fileContent = data?.blobContent?.rawData ?? '';

        this.lastCommittedContent = fileContent;
        this.currentCiFileContent = fileContent;
      },
      error(error) {
        this.handleBlobContentError(error);
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
          content: this.currentCiFileContent,
        };
      },
      update(data) {
        const { ciConfig } = data || {};
        const stageNodes = ciConfig?.stages?.nodes || [];
        const stages = unwrapStagesWithNeeds(stageNodes);

        return { ...ciConfig, stages };
      },
      result({ data }) {
        this.setAppStatus(data?.ciConfig?.status || EDITOR_APP_STATUS_ERROR);
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
    appStatus: {
      query: getAppStatus,
    },
    currentBranch: {
      query: getCurrentBranch,
    },
    isNewCiConfigFile: {
      query: getIsNewCiConfigFile,
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
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE_UNKNOWN:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE_UNKNOWN],
            variant: 'danger',
          };
        case COMMIT_FAILURE:
          return {
            text: this.$options.errorTexts[COMMIT_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT_FAILURE],
            variant: 'danger',
          };
      }
    },
    success() {
      switch (this.successType) {
        case COMMIT_SUCCESS:
          return {
            text: this.$options.successTexts[COMMIT_SUCCESS],
            variant: 'info',
          };
        default:
          return null;
      }
    },
  },
  i18n: {
    tabEdit: s__('Pipelines|Write pipeline configuration'),
    tabGraph: s__('Pipelines|Visualize'),
    tabLint: s__('Pipelines|Lint'),
  },
  errorTexts: {
    [COMMIT_FAILURE]: s__('Pipelines|The GitLab CI configuration could not be updated.'),
    [DEFAULT_FAILURE]: __('Something went wrong on our end.'),
    [LOAD_FAILURE_UNKNOWN]: s__('Pipelines|The CI configuration was not loaded, please try again.'),
  },
  successTexts: {
    [COMMIT_SUCCESS]: __('Your changes have been successfully committed.'),
  },
  watch: {
    isEmpty(flag) {
      if (flag) {
        this.setAppStatus(EDITOR_APP_STATUS_EMPTY);
      }
    },
  },
  methods: {
    handleBlobContentError(error = {}) {
      const { networkError } = error;

      const { response } = networkError;
      // 404 for missing CI file
      // 400 for blank projects with no repository
      if (
        response?.status === httpStatusCodes.NOT_FOUND ||
        response?.status === httpStatusCodes.BAD_REQUEST
      ) {
        this.setAppStatus(EDITOR_APP_STATUS_EMPTY);
        this.showStartScreen = true;
      } else {
        this.reportFailure(LOAD_FAILURE_UNKNOWN);
      }
    },

    dismissFailure() {
      this.showFailureAlert = false;
    },
    dismissSuccess() {
      this.showSuccessAlert = false;
    },
    reportFailure(type, reasons = []) {
      this.setAppStatus(EDITOR_APP_STATUS_ERROR);

      window.scrollTo({ top: 0, behavior: 'smooth' });
      this.showFailureAlert = true;
      this.failureType = type;
      this.failureReasons = reasons;
    },
    reportSuccess(type) {
      window.scrollTo({ top: 0, behavior: 'smooth' });
      this.showSuccessAlert = true;
      this.successType = type;
    },
    resetContent() {
      this.currentCiFileContent = this.lastCommittedContent;
    },
    setAppStatus(appStatus) {
      this.$apollo.getClient().writeQuery({ query: getAppStatus, data: { appStatus } });
    },
    setNewEmptyCiConfigFile() {
      this.$apollo
        .getClient()
        .writeQuery({ query: getIsNewCiConfigFile, data: { isNewCiConfigFile: true } });
      this.showStartScreen = false;
    },
    showErrorAlert({ type, reasons = [] }) {
      this.reportFailure(type, reasons);
    },
    updateCiConfig(ciFileContent) {
      this.currentCiFileContent = ciFileContent;
    },
    updateOnCommit({ type }) {
      this.reportSuccess(type);

      if (this.isNewCiConfigFile) {
        this.$apollo
          .getClient()
          .writeQuery({ query: getIsNewCiConfigFile, data: { isNewCiConfigFile: false } });
      }
      // Keep track of the latest commited content to know
      // if the user has made changes to the file that are unsaved.
      this.lastCommittedContent = this.currentCiFileContent;
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
    />
    <div v-else>
      <gl-alert
        v-if="showSuccessAlert"
        :variant="success.variant"
        class="gl-mb-5"
        @dismiss="dismissSuccess"
      >
        {{ success.text }}
      </gl-alert>
      <gl-alert
        v-if="showFailureAlert"
        :variant="failure.variant"
        class="gl-mb-5"
        @dismiss="dismissFailure"
      >
        {{ failure.text }}
        <ul v-if="failureReasons.length" class="gl-mb-0">
          <li v-for="reason in failureReasons" :key="reason">{{ reason }}</li>
        </ul>
      </gl-alert>
      <pipeline-editor-home
        :ci-config-data="ciConfigData"
        :ci-file-content="currentCiFileContent"
        :is-new-ci-config-file="isNewCiConfigFile"
        @commit="updateOnCommit"
        @resetContent="resetContent"
        @showError="showErrorAlert"
        @updateCiConfig="updateCiConfig"
      />
      <confirm-unsaved-changes-dialog :has-unsaved-changes="hasUnsavedChanges" />
    </div>
  </div>
</template>
