<script>
import { GlAlert, GlLoadingIcon, GlTabs, GlTab } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { mergeUrlParams, redirectTo } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import httpStatusCodes from '~/lib/utils/http_status';

import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import CiLint from './components/lint/ci_lint.vue';
import CommitForm from './components/commit/commit_form.vue';
import EditorTab from './components/ui/editor_tab.vue';
import TextEditor from './components/text_editor.vue';
import ValidationSegment from './components/info/validation_segment.vue';

import commitCiFileMutation from './graphql/mutations/commit_ci_file.mutation.graphql';
import getBlobContent from './graphql/queries/blob_content.graphql';
import getCiConfigData from './graphql/queries/ci_config.graphql';
import { unwrapStagesWithNeeds } from '~/pipelines/components/unwrapping_utils';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';

const COMMIT_FAILURE = 'COMMIT_FAILURE';
const COMMIT_SUCCESS = 'COMMIT_SUCCESS';
const DEFAULT_FAILURE = 'DEFAULT_FAILURE';
const LOAD_FAILURE_NO_FILE = 'LOAD_FAILURE_NO_FILE';
const LOAD_FAILURE_UNKNOWN = 'LOAD_FAILURE_UNKNOWN';

export default {
  components: {
    CiLint,
    CommitForm,
    EditorTab,
    GlAlert,
    GlLoadingIcon,
    GlTabs,
    GlTab,
    PipelineGraph,
    TextEditor,
    ValidationSegment,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectFullPath'],
  props: {
    defaultBranch: {
      type: String,
      required: false,
      default: null,
    },
    commitSha: {
      type: String,
      required: false,
      default: null,
    },
    ciConfigPath: {
      type: String,
      required: true,
    },
    newMergeRequestPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      ciConfigData: {},
      content: '',
      contentModel: '',
      lastCommitSha: this.commitSha,
      isSaving: false,

      // Success and failure state
      failureType: null,
      showFailureAlert: false,
      failureReasons: [],
      successType: null,
      showSuccessAlert: false,
    };
  },
  apollo: {
    content: {
      query: getBlobContent,
      variables() {
        return {
          projectPath: this.projectFullPath,
          path: this.ciConfigPath,
          ref: this.defaultBranch,
        };
      },
      update(data) {
        return data?.blobContent?.rawData;
      },
      result({ data }) {
        this.contentModel = data?.blobContent?.rawData ?? '';
      },
      error(error) {
        this.handleBlobContentError(error);
      },
    },
    ciConfigData: {
      query: getCiConfigData,
      // If content is not loaded, we can't lint the data
      skip: ({ contentModel }) => {
        return !contentModel;
      },
      variables() {
        return {
          projectPath: this.projectFullPath,
          content: this.contentModel,
        };
      },
      update(data) {
        const { ciConfig } = data || {};
        const stageNodes = ciConfig?.stages?.nodes || [];
        const stages = unwrapStagesWithNeeds(stageNodes);

        return { ...ciConfig, stages };
      },
      error() {
        this.reportFailure(LOAD_FAILURE_UNKNOWN);
      },
    },
  },
  computed: {
    isBlobContentLoading() {
      return this.$apollo.queries.content.loading;
    },
    isBlobContentError() {
      return this.failureType === LOAD_FAILURE_NO_FILE;
    },
    isCiConfigDataLoading() {
      return this.$apollo.queries.ciConfigData.loading;
    },
    defaultCommitMessage() {
      return sprintf(this.$options.i18n.defaultCommitMessage, { sourcePath: this.ciConfigPath });
    },
    success() {
      switch (this.successType) {
        case COMMIT_SUCCESS:
          return {
            text: this.$options.alertTexts[COMMIT_SUCCESS],
            variant: 'info',
          };
        default:
          return null;
      }
    },
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE_NO_FILE:
          return {
            text: sprintf(this.$options.alertTexts[LOAD_FAILURE_NO_FILE], {
              filePath: this.ciConfigPath,
            }),
            variant: 'danger',
          };
        case LOAD_FAILURE_UNKNOWN:
          return {
            text: this.$options.alertTexts[LOAD_FAILURE_UNKNOWN],
            variant: 'danger',
          };
        case COMMIT_FAILURE:
          return {
            text: this.$options.alertTexts[COMMIT_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: this.$options.alertTexts[DEFAULT_FAILURE],
            variant: 'danger',
          };
      }
    },
  },
  i18n: {
    defaultCommitMessage: __('Update %{sourcePath} file'),
    tabEdit: s__('Pipelines|Write pipeline configuration'),
    tabGraph: s__('Pipelines|Visualize'),
    tabLint: s__('Pipelines|Lint'),
  },
  alertTexts: {
    [COMMIT_FAILURE]: s__('Pipelines|The GitLab CI configuration could not be updated.'),
    [COMMIT_SUCCESS]: __('Your changes have been successfully committed.'),
    [DEFAULT_FAILURE]: __('Something went wrong on our end.'),
    [LOAD_FAILURE_NO_FILE]: s__(
      'Pipelines|There is no %{filePath} file in this repository, please add one and visit the Pipeline Editor again.',
    ),
    [LOAD_FAILURE_UNKNOWN]: s__('Pipelines|The CI configuration was not loaded, please try again.'),
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
        this.reportFailure(LOAD_FAILURE_NO_FILE);
      } else {
        this.reportFailure(LOAD_FAILURE_UNKNOWN);
      }
    },

    dismissFailure() {
      this.showFailureAlert = false;
    },
    reportFailure(type, reasons = []) {
      this.showFailureAlert = true;
      this.failureType = type;
      this.failureReasons = reasons;
    },
    dismissSuccess() {
      this.showSuccessAlert = false;
    },
    reportSuccess(type) {
      this.showSuccessAlert = true;
      this.successType = type;
    },

    redirectToNewMergeRequest(sourceBranch) {
      const url = mergeUrlParams(
        {
          [MR_SOURCE_BRANCH]: sourceBranch,
          [MR_TARGET_BRANCH]: this.defaultBranch,
        },
        this.newMergeRequestPath,
      );
      redirectTo(url);
    },
    async onCommitSubmit(event) {
      this.isSaving = true;
      const { message, branch, openMergeRequest } = event;

      try {
        const {
          data: {
            commitCreate: { errors, commit },
          },
        } = await this.$apollo.mutate({
          mutation: commitCiFileMutation,
          variables: {
            projectPath: this.projectFullPath,
            branch,
            startBranch: this.defaultBranch,
            message,
            filePath: this.ciConfigPath,
            content: this.contentModel,
            lastCommitId: this.lastCommitSha,
          },
        });

        if (errors?.length) {
          this.reportFailure(COMMIT_FAILURE, errors);
          return;
        }

        if (openMergeRequest) {
          this.redirectToNewMergeRequest(branch);
        } else {
          this.reportSuccess(COMMIT_SUCCESS);

          // Update latest commit
          this.lastCommitSha = commit.sha;
        }
      } catch (error) {
        this.reportFailure(COMMIT_FAILURE, [error?.message]);
      } finally {
        this.isSaving = false;
      }
    },
    onCommitCancel() {
      this.contentModel = this.content;
    },
  },
};
</script>

<template>
  <div class="gl-mt-4">
    <gl-alert
      v-if="showSuccessAlert"
      :variant="success.variant"
      :dismissible="true"
      @dismiss="dismissSuccess"
    >
      {{ success.text }}
    </gl-alert>
    <gl-alert
      v-if="showFailureAlert"
      :variant="failure.variant"
      :dismissible="true"
      @dismiss="dismissFailure"
    >
      {{ failure.text }}
      <ul v-if="failureReasons.length" class="gl-mb-0">
        <li v-for="reason in failureReasons" :key="reason">{{ reason }}</li>
      </ul>
    </gl-alert>
    <gl-loading-icon v-if="isBlobContentLoading" size="lg" class="gl-m-3" />
    <div v-else-if="!isBlobContentError" class="gl-mt-4">
      <div class="file-editor gl-mb-3">
        <div class="info-well gl-display-none gl-sm-display-block">
          <validation-segment
            class="well-segment"
            :loading="isCiConfigDataLoading"
            :ci-config="ciConfigData"
          />
        </div>

        <gl-tabs>
          <editor-tab :lazy="true" :title="$options.i18n.tabEdit">
            <text-editor
              v-model="contentModel"
              :ci-config-path="ciConfigPath"
              :commit-sha="lastCommitSha"
            />
          </editor-tab>
          <gl-tab
            v-if="glFeatures.ciConfigVisualizationTab"
            :lazy="true"
            :title="$options.i18n.tabGraph"
            data-testid="visualization-tab"
          >
            <gl-loading-icon v-if="isCiConfigDataLoading" size="lg" class="gl-m-3" />
            <pipeline-graph v-else :pipeline-data="ciConfigData" />
          </gl-tab>

          <editor-tab :title="$options.i18n.tabLint">
            <gl-loading-icon v-if="isCiConfigDataLoading" size="lg" class="gl-m-3" />
            <ci-lint v-else :ci-config="ciConfigData" />
          </editor-tab>
        </gl-tabs>
      </div>
      <commit-form
        :default-branch="defaultBranch"
        :default-message="defaultCommitMessage"
        :is-saving="isSaving"
        @cancel="onCommitCancel"
        @submit="onCommitSubmit"
      />
    </div>
  </div>
</template>
