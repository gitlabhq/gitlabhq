<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { projectNewMergeRequestPath } from '~/lib/utils/path_helpers/merge_requests';
import branchMergeRequestQuery from '../graphql/queries/branch_merge_request.query.graphql';
import branchNamesQuery from '../graphql/queries/branch_names.query.graphql';

export default {
  name: 'CommitsMergeRequestButton',
  components: {
    GlButton,
  },
  inject: {
    projectFullPath: { default: '' },
    rootRef: { default: '' },
  },
  props: {
    currentRef: {
      type: String,
      required: false,
      default: '',
    },
    refType: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['merge-request-action'],
  data() {
    return {
      project: null,
      branchNames: [],
    };
  },
  apollo: {
    project: {
      query: branchMergeRequestQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          sourceBranch: this.currentRef,
          targetBranch: this.rootRef,
        };
      },
      skip() {
        return this.shouldSkipQuery;
      },
      error(error) {
        logError(`Failed to fetch merge request data for the current ref.`, error);
        Sentry.captureException(error);
      },
    },
    branchNames: {
      query: branchNamesQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.currentRef,
        };
      },
      update(data) {
        return data?.project?.repository?.branchNames || [];
      },
      skip() {
        return this.shouldSkipBranchNamesQuery;
      },
      error(error) {
        logError(`Failed to fetch branch names for the current ref.`, error);
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    shouldSkipQuery() {
      return (
        !this.currentRef ||
        !this.rootRef ||
        this.currentRef === this.rootRef ||
        this.refType === 'tags'
      );
    },
    shouldSkipBranchNamesQuery() {
      // Branch existence only needs verifying when the ref type is unknown
      // (e.g. a direct URL visit where the ref could be a commit SHA), and
      // only when the create button could actually show.
      return (
        this.shouldSkipQuery ||
        this.refType === 'heads' ||
        Boolean(this.openMergeRequest) ||
        !this.hasCreateMergeRequestPermissions
      );
    },
    isLoading() {
      return Boolean(
        this.$apollo.queries.project?.loading || this.$apollo.queries.branchNames?.loading,
      );
    },
    openMergeRequest() {
      return this.project?.mergeRequests?.nodes?.[0] || null;
    },
    hasCreateMergeRequestPermissions() {
      const permissions = this.project?.userPermissions;
      return Boolean(permissions?.createMergeRequestFrom && permissions?.createMergeRequestIn);
    },
    isBranch() {
      if (this.refType === 'heads') return true;
      return this.branchNames.includes(this.currentRef);
    },
    showViewMergeRequestButton() {
      return !this.shouldSkipQuery && !this.isLoading && Boolean(this.openMergeRequest);
    },
    showCreateMergeRequestButton() {
      return (
        !this.shouldSkipQuery &&
        !this.isLoading &&
        !this.openMergeRequest &&
        this.hasCreateMergeRequestPermissions &&
        this.isBranch
      );
    },
    createMergeRequestPath() {
      return projectNewMergeRequestPath(this.projectFullPath, {
        merge_request: { source_branch: this.currentRef },
      });
    },
    mergeRequestAction() {
      if (this.showViewMergeRequestButton) {
        return {
          text: __('View open merge request'),
          href: this.openMergeRequest.webPath,
          variant: 'default',
          testid: 'view-merge-request-link',
          buttonTestid: 'view-merge-request-button',
        };
      }
      if (this.showCreateMergeRequestButton) {
        return {
          text: __('Create merge request'),
          href: this.createMergeRequestPath,
          variant: 'confirm',
          testid: 'create-merge-request-link',
          buttonTestid: 'create-merge-request-button',
        };
      }
      return null;
    },
  },
  watch: {
    mergeRequestAction(action) {
      this.$emit('merge-request-action', action);
    },
  },
};
</script>

<template>
  <gl-button
    v-if="mergeRequestAction"
    :href="mergeRequestAction.href"
    :variant="mergeRequestAction.variant"
    :data-testid="mergeRequestAction.buttonTestid"
  >
    {{ mergeRequestAction.text }}
  </gl-button>
</template>
