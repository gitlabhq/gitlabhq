<script>
import { __, s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import {
  COMMIT_ACTION_CREATE,
  COMMIT_ACTION_UPDATE,
  COMMIT_FAILURE,
  COMMIT_SUCCESS,
  COMMIT_SUCCESS_WITH_REDIRECT,
  pipelineEditorTrackingOptions,
} from '../../constants';
import commitCIFile from '../../graphql/mutations/commit_ci_file.mutation.graphql';
import updateCurrentBranchMutation from '../../graphql/mutations/client/update_current_branch.mutation.graphql';
import updateLastCommitBranchMutation from '../../graphql/mutations/client/update_last_commit_branch.mutation.graphql';
import updatePipelineEtag from '../../graphql/mutations/client/update_pipeline_etag.mutation.graphql';
import getCurrentBranch from '../../graphql/queries/client/current_branch.query.graphql';

import CommitForm from './commit_form.vue';

export default {
  alertTexts: {
    [COMMIT_FAILURE]: s__('Pipelines|The GitLab CI configuration could not be updated.'),
    [COMMIT_SUCCESS]: __('Your changes have been successfully committed.'),
  },
  i18n: {
    defaultCommitMessage: __('Update %{sourcePath} file'),
  },
  components: {
    CommitForm,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectFullPath', 'ciConfigPath'],
  props: {
    ciFileContent: {
      type: String,
      required: true,
    },
    commitSha: {
      type: String,
      required: false,
      default: '',
    },
    hasUnsavedChanges: {
      type: Boolean,
      required: true,
    },
    isNewCiConfigFile: {
      type: Boolean,
      required: false,
      default: false,
    },
    scrollToCommitForm: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      commit: {},
      isSaving: false,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    currentBranch: {
      query: getCurrentBranch,
      update(data) {
        return data.workBranches.current.name;
      },
    },
  },
  computed: {
    action() {
      return this.isNewCiConfigFile ? COMMIT_ACTION_CREATE : COMMIT_ACTION_UPDATE;
    },
    defaultCommitMessage() {
      return sprintf(this.$options.i18n.defaultCommitMessage, { sourcePath: this.ciConfigPath });
    },
  },
  methods: {
    async onCommitSubmit({ message, sourceBranch, openMergeRequest }) {
      this.isSaving = true;

      this.trackCommitEvent();

      try {
        const {
          data: {
            commitCreate: { errors, commitPipelinePath: pipelineEtag },
          },
        } = await this.$apollo.mutate({
          mutation: commitCIFile,
          variables: {
            action: this.action,
            projectPath: this.projectFullPath,
            branch: sourceBranch,
            startBranch: this.currentBranch,
            message,
            filePath: this.ciConfigPath,
            content: this.ciFileContent,
            lastCommitId: this.commitSha,
          },
        });

        if (pipelineEtag) {
          this.updatePipelineEtag(pipelineEtag);
        }

        if (errors?.length) {
          this.$emit('showError', { type: COMMIT_FAILURE, reasons: errors });
        } else {
          const params = openMergeRequest
            ? {
                type: COMMIT_SUCCESS_WITH_REDIRECT,
                params: {
                  sourceBranch,
                  targetBranch: this.currentBranch,
                },
              }
            : { type: COMMIT_SUCCESS };

          this.$emit('commit', {
            ...params,
          });

          this.updateLastCommitBranch(sourceBranch);
          this.updateCurrentBranch(sourceBranch);

          if (this.currentBranch === sourceBranch) {
            this.$emit('updateCommitSha');
          }
        }
      } catch (error) {
        this.$emit('showError', { type: COMMIT_FAILURE, reasons: [error?.message] });
      } finally {
        this.isSaving = false;
      }
    },
    trackCommitEvent() {
      const { label, actions } = pipelineEditorTrackingOptions;
      this.track(actions.commitCiConfig, { label, property: this.action });
    },
    updateCurrentBranch(currentBranch) {
      this.$apollo.mutate({
        mutation: updateCurrentBranchMutation,
        variables: { currentBranch },
      });
    },
    updateLastCommitBranch(lastCommitBranch) {
      this.$apollo.mutate({
        mutation: updateLastCommitBranchMutation,
        variables: { lastCommitBranch },
      });
    },
    updatePipelineEtag(pipelineEtag) {
      this.$apollo.mutate({ mutation: updatePipelineEtag, variables: { pipelineEtag } });
    },
  },
};
</script>

<template>
  <commit-form
    :current-branch="currentBranch"
    :default-message="defaultCommitMessage"
    :has-unsaved-changes="hasUnsavedChanges"
    :is-new-ci-config-file="isNewCiConfigFile"
    :is-saving="isSaving"
    :scroll-to-commit-form="scrollToCommitForm"
    v-on="$listeners"
    @submit="onCommitSubmit"
  />
</template>
