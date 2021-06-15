<script>
import { mergeUrlParams, redirectTo } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import {
  COMMIT_ACTION_CREATE,
  COMMIT_ACTION_UPDATE,
  COMMIT_FAILURE,
  COMMIT_SUCCESS,
} from '../../constants';
import commitCIFile from '../../graphql/mutations/commit_ci_file.mutation.graphql';
import updateCurrentBranchMutation from '../../graphql/mutations/update_current_branch.mutation.graphql';
import updateLastCommitBranchMutation from '../../graphql/mutations/update_last_commit_branch.mutation.graphql';
import getCommitSha from '../../graphql/queries/client/commit_sha.graphql';
import getCurrentBranch from '../../graphql/queries/client/current_branch.graphql';
import getIsNewCiConfigFile from '../../graphql/queries/client/is_new_ci_config_file.graphql';
import getPipelineEtag from '../../graphql/queries/client/pipeline_etag.graphql';

import CommitForm from './commit_form.vue';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';

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
  inject: ['projectFullPath', 'ciConfigPath', 'newMergeRequestPath'],
  props: {
    ciFileContent: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      commit: {},
      isNewCiConfigFile: false,
      isSaving: false,
    };
  },
  apollo: {
    isNewCiConfigFile: {
      query: getIsNewCiConfigFile,
    },
    commitSha: {
      query: getCommitSha,
    },
    currentBranch: {
      query: getCurrentBranch,
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
    redirectToNewMergeRequest(sourceBranch) {
      const url = mergeUrlParams(
        {
          [MR_SOURCE_BRANCH]: sourceBranch,
          [MR_TARGET_BRANCH]: this.currentBranch,
        },
        this.newMergeRequestPath,
      );
      redirectTo(url);
    },
    async onCommitSubmit({ message, targetBranch, openMergeRequest }) {
      this.isSaving = true;

      try {
        const {
          data: {
            commitCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: commitCIFile,
          variables: {
            action: this.action,
            projectPath: this.projectFullPath,
            branch: targetBranch,
            startBranch: this.currentBranch,
            message,
            filePath: this.ciConfigPath,
            content: this.ciFileContent,
            lastCommitId: this.commitSha,
          },
          update(store, { data }) {
            const commitSha = data?.commitCreate?.commit?.sha;
            const pipelineEtag = data?.commitCreate?.commit?.commitPipelinePath;

            if (commitSha) {
              store.writeQuery({ query: getCommitSha, data: { commitSha } });
            }

            if (pipelineEtag) {
              store.writeQuery({ query: getPipelineEtag, data: { pipelineEtag } });
            }
          },
        });

        if (errors?.length) {
          this.$emit('showError', { type: COMMIT_FAILURE, reasons: errors });
        } else if (openMergeRequest) {
          this.redirectToNewMergeRequest(targetBranch);
        } else {
          this.$emit('commit', { type: COMMIT_SUCCESS });
          this.updateLastCommitBranch(targetBranch);
          this.updateCurrentBranch(targetBranch);
        }
      } catch (error) {
        this.$emit('showError', { type: COMMIT_FAILURE, reasons: [error?.message] });
      } finally {
        this.isSaving = false;
      }
    },
    onCommitCancel() {
      this.$emit('resetContent');
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
  },
};
</script>

<template>
  <commit-form
    :current-branch="currentBranch"
    :default-message="defaultCommitMessage"
    :is-saving="isSaving"
    @cancel="onCommitCancel"
    @submit="onCommitSubmit"
  />
</template>
