<script>
import { __ } from '~/locale';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import conflictsStateQuery from '../../queries/states/conflicts.query.graphql';
import ActionButtons from '../action_buttons.vue';
import MergeChecksMessage from './message.vue';

export default {
  name: 'MergeChecksConflicts',
  components: {
    MergeChecksMessage,
    ActionButtons,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    state: {
      query: conflictsStateQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data?.project?.mergeRequest || null,
    },
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      state: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.state.loading || !this.state;
    },
    userPermissions() {
      return this.state.userPermissions;
    },
    showResolveButton() {
      return (
        this.mr.conflictResolutionPath &&
        this.userPermissions.pushToSourceBranch &&
        !this.state.sourceBranchProtected
      );
    },
    tertiaryActionsButtons() {
      if (this.state.shouldBeRebased) return [];

      return [
        {
          text: __('Resolve locally'),
          class: 'js-check-out-modal-trigger',
        },
        this.showResolveButton && {
          text: __('Resolve conflicts'),
          category: 'default',
          href: this.mr.conflictResolutionPath,
        },
      ].filter((b) => b);
    },
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template #failed>
      <action-buttons v-if="!isLoading" :tertiary-buttons="tertiaryActionsButtons" />
    </template>
  </merge-checks-message>
</template>
