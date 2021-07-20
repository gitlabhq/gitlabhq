<script>
import { GlButton, GlModalDirective, GlSkeletonLoader } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import userPermissionsQuery from '../../queries/permissions.query.graphql';
import conflictsStateQuery from '../../queries/states/conflicts.query.graphql';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetConflicts',
  components: {
    GlSkeletonLoader,
    StatusIcon,
    GlButton,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  apollo: {
    userPermissions: {
      query: userPermissionsQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest.userPermissions,
    },
    stateData: {
      query: conflictsStateQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest,
    },
  },
  props: {
    /* TODO: This is providing all store and service down when it
      only needs a few props */
    mr: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  data() {
    return {
      userPermissions: {},
      stateData: {},
    };
  },
  computed: {
    isLoading() {
      return (
        this.glFeatures.mergeRequestWidgetGraphql &&
        this.$apollo.queries.userPermissions.loading &&
        this.$apollo.queries.stateData.loading
      );
    },
    canPushToSourceBranch() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.userPermissions.pushToSourceBranch;
      }

      return this.mr.canPushToSourceBranch;
    },
    canMerge() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.userPermissions.canMerge;
      }

      return this.mr.canMerge;
    },
    shouldBeRebased() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.stateData.shouldBeRebased;
      }

      return this.mr.shouldBeRebased;
    },
    sourceBranchProtected() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.stateData.sourceBranchProtected;
      }

      return this.mr.sourceBranchProtected;
    },
    showResolveButton() {
      return (
        this.mr.conflictResolutionPath && this.canPushToSourceBranch && !this.sourceBranchProtected
      );
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />

    <div v-if="isLoading" class="gl-ml-4 gl-w-full mr-conflict-loader">
      <gl-skeleton-loader :width="334" :height="30">
        <rect x="0" y="7" width="150" height="16" rx="4" />
        <rect x="158" y="7" width="84" height="16" rx="4" />
        <rect x="250" y="7" width="84" height="16" rx="4" />
      </gl-skeleton-loader>
    </div>
    <div v-else class="media-body space-children gl-display-flex gl-align-items-center">
      <span v-if="shouldBeRebased" class="bold">
        {{
          s__(`mrWidget|Merge blocked: fast-forward merge is not possible.
  To merge this request, first rebase locally.`)
        }}
      </span>
      <template v-else>
        <span class="bold">
          {{ s__('mrWidget|There are merge conflicts') }}<span v-if="!canMerge">.</span>
          <span v-if="!canMerge">
            {{
              s__(`mrWidget|Resolve these conflicts or ask someone
              with write access to this repository to merge it locally`)
            }}
          </span>
        </span>
        <gl-button
          v-if="showResolveButton"
          :href="mr.conflictResolutionPath"
          data-testid="resolve-conflicts-button"
        >
          {{ s__('mrWidget|Resolve conflicts') }}
        </gl-button>
        <gl-button
          v-if="canMerge"
          v-gl-modal-directive="'modal-merge-info'"
          data-testid="merge-locally-button"
        >
          {{ s__('mrWidget|Merge locally') }}
        </gl-button>
      </template>
    </div>
  </div>
</template>
