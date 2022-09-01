<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import userPermissionsQuery from '../../queries/permissions.query.graphql';
import conflictsStateQuery from '../../queries/states/conflicts.query.graphql';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetConflicts',
  components: {
    GlSkeletonLoader,
    GlButton,
    StateContainer,
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
  <state-container :mr="mr" status="failed" :is-loading="isLoading">
    <template #loading>
      <gl-skeleton-loader :width="334" :height="30">
        <rect x="0" y="7" width="150" height="16" rx="4" />
        <rect x="158" y="7" width="84" height="16" rx="4" />
        <rect x="250" y="7" width="84" height="16" rx="4" />
      </gl-skeleton-loader>
    </template>
    <template v-if="!isLoading">
      <span v-if="shouldBeRebased" class="bold gl-ml-0! gl-text-body!">
        {{
          s__(`mrWidget|Merge blocked: fast-forward merge is not possible.
  To merge this request, first rebase locally.`)
        }}
      </span>
      <template v-else>
        <span class="bold gl-ml-0! gl-text-body! gl-flex-grow-1 gl-w-full gl-md-w-auto gl-mr-2">
          {{ s__('mrWidget|Merge blocked: merge conflicts must be resolved.') }}
          <span v-if="!canMerge">
            {{
              s__(
                `mrWidget|Users who can write to the source or target branches can resolve the conflicts.`,
              )
            }}
          </span>
        </span>
      </template>
    </template>
    <template v-if="!isLoading && !shouldBeRebased" #actions>
      <gl-button
        v-if="canMerge"
        size="small"
        variant="confirm"
        category="secondary"
        data-testid="merge-locally-button"
        class="js-check-out-modal-trigger gl-align-self-start"
        :class="{ 'gl-mr-2': showResolveButton }"
      >
        {{ s__('mrWidget|Resolve locally') }}
      </gl-button>
      <gl-button
        v-if="showResolveButton"
        :href="mr.conflictResolutionPath"
        size="small"
        variant="confirm"
        class="gl-mb-2 gl-md-mb-0 gl-align-self-start"
        data-testid="resolve-conflicts-button"
      >
        {{ s__('mrWidget|Resolve conflicts') }}
      </gl-button>
    </template>
  </state-container>
</template>
