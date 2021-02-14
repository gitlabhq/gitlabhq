<script>
import { mergeUrlParams, redirectTo } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { COMMIT_FAILURE, COMMIT_SUCCESS } from '../../constants';
import commitCIFile from '../../graphql/mutations/commit_ci_file.mutation.graphql';
import getCommitSha from '../../graphql/queries/client/commit_sha.graphql';

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
  inject: ['projectFullPath', 'ciConfigPath', 'defaultBranch', 'newMergeRequestPath'],
  props: {
    ciFileContent: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      commit: {},
      isSaving: false,
    };
  },
  apollo: {
    commitSha: {
      query: getCommitSha,
    },
  },
  computed: {
    defaultCommitMessage() {
      return sprintf(this.$options.i18n.defaultCommitMessage, { sourcePath: this.ciConfigPath });
    },
  },
  methods: {
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
    async onCommitSubmit({ message, branch, openMergeRequest }) {
      this.isSaving = true;

      try {
        const {
          data: {
            commitCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: commitCIFile,
          variables: {
            projectPath: this.projectFullPath,
            branch,
            startBranch: this.defaultBranch,
            message,
            filePath: this.ciConfigPath,
            content: this.ciFileContent,
            lastCommitId: this.commitSha,
          },
          update(store, { data }) {
            const commitSha = data?.commitCreate?.commit?.sha;

            if (commitSha) {
              store.writeQuery({ query: getCommitSha, data: { commitSha } });
            }
          },
        });

        if (errors?.length) {
          this.$emit('showError', { type: COMMIT_FAILURE, reasons: errors });
        } else if (openMergeRequest) {
          this.redirectToNewMergeRequest(branch);
        } else {
          this.$emit('commit', { type: COMMIT_SUCCESS });
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
  },
};
</script>

<template>
  <commit-form
    :default-branch="defaultBranch"
    :default-message="defaultCommitMessage"
    :is-saving="isSaving"
    @cancel="onCommitCancel"
    @submit="onCommitSubmit"
  />
</template>
