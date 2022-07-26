<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
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
    showResolveButton() {
      return this.mr.conflictResolutionPath && this.canPushToSourceBranch;
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
      <span v-if="shouldBeRebased" class="gl-ml-0! gl-text-body! bold">
        {{
          s__(`mrWidget|Merge blocked: fast-forward merge is not possible.
  To merge this request, first rebase locally.`)
        }}
      </span>
      <template v-else>
        <span class="gl-ml-0! gl-text-body! bold">
          {{ s__('mrWidget|Merge blocked: merge conflicts must be resolved.') }}
          <span v-if="!canMerge">
            {{
              s__(
                `mrWidget|Users who can write to the source or target branches can resolve the conflicts.`,
              )
            }}
          </span>
        </span>
        <gl-button
          v-if="showResolveButton"
          :href="mr.conflictResolutionPath"
          size="small"
          data-testid="resolve-conflicts-button"
        >
          {{ s__('mrWidget|Resolve conflicts') }}
        </gl-button>
        <gl-button
          v-if="canMerge"
          size="small"
          data-testid="merge-locally-button"
          class="js-check-out-modal-trigger"
        >
          {{ s__('mrWidget|Resolve locally') }}
        </gl-button>
      </template>
    </div>
  </div>
</template>
