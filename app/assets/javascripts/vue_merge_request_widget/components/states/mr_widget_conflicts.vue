<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import { s__ } from '~/locale';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import userPermissionsQuery from '../../queries/permissions.query.graphql';
import conflictsStateQuery from '../../queries/states/conflicts.query.graphql';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetConflicts',
  components: {
    BoldText,
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
      update: (data) => data.project?.mergeRequest?.userPermissions || {},
    },
    state: {
      query: conflictsStateQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest || {},
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
  i18n: {
    shouldBeRebased: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} fast-forward merge is not possible. To merge this request, first rebase locally.',
    ),
    shouldBeResolved: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} merge conflicts must be resolved.',
    ),
    usersWriteBranches: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} Users who can write to the source or target branches can resolve the conflicts.',
    ),
  },
};
</script>
<template>
  <state-container
    status="failed"
    :is-loading="isLoading"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <template #loading>
      <gl-skeleton-loader :width="334" :height="24">
        <rect x="0" y="0" width="24" height="24" rx="4" />
        <rect x="32" y="2" width="150" height="20" rx="4" />
        <rect x="190" y="2" width="144" height="20" rx="4" />
      </gl-skeleton-loader>
    </template>
    <template v-if="!isLoading">
      <span v-if="state.shouldBeRebased" class="gl-ml-0! gl-text-body!">
        <bold-text :message="$options.i18n.shouldBeRebased" />
      </span>
      <template v-else>
        <span class="gl-ml-0! gl-text-body! gl-flex-grow-1 gl-w-full gl-md-w-auto gl-mr-2">
          <bold-text v-if="userPermissions.canMerge" :message="$options.i18n.shouldBeResolved" />
          <bold-text v-else :message="$options.i18n.usersWriteBranches" />
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
        category="tertiary"
        data-testid="merge-locally-button"
        class="js-check-out-modal-trigger gl-align-self-start"
      >
        {{ s__('mrWidget|Resolve locally') }}
      </gl-button>
    </template>
  </state-container>
</template>
