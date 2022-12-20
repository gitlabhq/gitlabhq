<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
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
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    userPermissions: {
      query: userPermissionsQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest.userPermissions,
    },
    state: {
      query: conflictsStateQuery,
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
      state: {},
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.userPermissions.loading && this.$apollo.queries.state.loading;
    },
    showResolveButton() {
      return (
        this.mr.conflictResolutionPath &&
        this.userPermissions.pushToSourceBranch &&
        !this.state.sourceBranchProtected
      );
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
      <span v-if="state.shouldBeRebased" class="bold gl-ml-0! gl-text-body!">
        {{
          s__(`mrWidget|Merge blocked: fast-forward merge is not possible.
  To merge this request, first rebase locally.`)
        }}
      </span>
      <template v-else>
        <span class="bold gl-ml-0! gl-text-body! gl-flex-grow-1 gl-w-full gl-md-w-auto gl-mr-2">
          {{ s__('mrWidget|Merge blocked: merge conflicts must be resolved.') }}
          <span v-if="!userPermissions.canMerge">
            {{
              s__(
                `mrWidget|Users who can write to the source or target branches can resolve the conflicts.`,
              )
            }}
          </span>
        </span>
      </template>
    </template>
    <template v-if="!isLoading && !state.shouldBeRebased" #actions>
      <gl-button
        v-if="showResolveButton"
        :href="mr.conflictResolutionPath"
        size="small"
        variant="confirm"
        class="gl-align-self-start"
        data-testid="resolve-conflicts-button"
      >
        {{ s__('mrWidget|Resolve conflicts') }}
      </gl-button>
      <gl-button
        v-if="userPermissions.canMerge"
        size="small"
        variant="confirm"
        category="secondary"
        data-testid="merge-locally-button"
        class="js-check-out-modal-trigger gl-align-self-start"
      >
        {{ s__('mrWidget|Resolve locally') }}
      </gl-button>
    </template>
  </state-container>
</template>
