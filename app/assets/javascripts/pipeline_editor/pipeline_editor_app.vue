<script>
import { GlAlert, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { redirectTo, mergeUrlParams, refreshCurrentPage } from '~/lib/utils/url_utility';

import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import CommitForm from './components/commit/commit_form.vue';
import TextEditor from './components/text_editor.vue';

import commitCiFileMutation from './graphql/mutations/commit_ci_file.mutation.graphql';
import getBlobContent from './graphql/queries/blob_content.graphql';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';

const LOAD_FAILURE_NO_REF = 'LOAD_FAILURE_NO_REF';
const LOAD_FAILURE_NO_FILE = 'LOAD_FAILURE_NO_FILE';
const LOAD_FAILURE_UNKNOWN = 'LOAD_FAILURE_UNKNOWN';
const COMMIT_FAILURE = 'COMMIT_FAILURE';
const DEFAULT_FAILURE = 'DEFAULT_FAILURE';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    GlTab,
    GlTabs,
    PipelineGraph,
    CommitForm,
    TextEditor,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: false,
      default: null,
    },
    commitId: {
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
      showFailureAlert: false,
      failureType: null,
      failureReasons: [],

      isSaving: false,
      editorIsReady: false,
      content: '',
      contentModel: '',
    };
  },
  apollo: {
    content: {
      query: getBlobContent,
      variables() {
        return {
          projectPath: this.projectPath,
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
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.content.loading;
    },
    defaultCommitMessage() {
      return sprintf(this.$options.i18n.defaultCommitMessage, { sourcePath: this.ciConfigPath });
    },
    pipelineData() {
      // Note data will loaded as part of https://gitlab.com/gitlab-org/gitlab/-/issues/263141
      return {};
    },
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE_NO_REF:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE_NO_REF],
            variant: 'danger',
          };
        case LOAD_FAILURE_NO_FILE:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE_NO_FILE],
            variant: 'danger',
          };
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
  },
  i18n: {
    defaultCommitMessage: __('Update %{sourcePath} file'),
    tabEdit: s__('Pipelines|Write pipeline configuration'),
    tabGraph: s__('Pipelines|Visualize'),
  },
  errorTexts: {
    [LOAD_FAILURE_NO_REF]: s__(
      'Pipelines|Repository does not have a default branch, please set one.',
    ),
    [LOAD_FAILURE_NO_FILE]: s__('Pipelines|No CI file found in this repository, please add one.'),
    [LOAD_FAILURE_UNKNOWN]: s__('Pipelines|The CI configuration was not loaded, please try again.'),
    [COMMIT_FAILURE]: s__('Pipelines|The GitLab CI configuration could not be updated.'),
  },
  methods: {
    handleBlobContentError(error = {}) {
      const { networkError } = error;

      const { response } = networkError;
      if (response?.status === 404) {
        // 404 for missing CI file
        this.reportFailure(LOAD_FAILURE_NO_FILE);
      } else if (response?.status === 400) {
        // 400 for a missing ref when no default branch is set
        this.reportFailure(LOAD_FAILURE_NO_REF);
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
            commitCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: commitCiFileMutation,
          variables: {
            projectPath: this.projectPath,
            branch,
            startBranch: this.defaultBranch,
            message,
            filePath: this.ciConfigPath,
            content: this.contentModel,
            lastCommitId: this.commitId,
          },
        });

        if (errors?.length) {
          this.reportFailure(COMMIT_FAILURE, errors);
          return;
        }

        if (openMergeRequest) {
          this.redirectToNewMergeRequest(branch);
        } else {
          // Refresh the page to ensure commit is updated
          refreshCurrentPage();
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
    <div class="gl-mt-4">
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-m-3" />
      <div v-else class="file-editor gl-mb-3">
        <gl-tabs>
          <!-- editor should be mounted when its tab is visible, so the container has a size -->
          <gl-tab :title="$options.i18n.tabEdit" :lazy="!editorIsReady">
            <!-- editor should be mounted only once, when the tab is displayed -->
            <text-editor v-model="contentModel" @editor-ready="editorIsReady = true" />
          </gl-tab>

          <gl-tab :title="$options.i18n.tabGraph">
            <pipeline-graph :pipeline-data="pipelineData" />
          </gl-tab>
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
