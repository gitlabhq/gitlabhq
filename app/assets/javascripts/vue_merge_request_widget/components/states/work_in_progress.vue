<script>
import { GlButton } from '@gitlab/ui';
import { produce } from 'immer';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import MergeRequest from '~/merge_request';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import getStateQuery from '../../queries/get_state.query.graphql';
import draftQuery from '../../queries/states/draft.query.graphql';
import removeDraftMutation from '../../queries/toggle_draft.mutation.graphql';
import StateContainer from '../state_container.vue';

// Export for testing
export const MSG_SOMETHING_WENT_WRONG = __('Something went wrong. Please try again.');
export const MSG_MARK_READY = s__('mrWidget|Mark as ready');

export default {
  name: 'WorkInProgress',
  components: {
    BoldText,
    GlButton,
    StateContainer,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    userPermissions: {
      query: draftQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest?.userPermissions || {},
    },
  },
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      userPermissions: {},
      isMakingRequest: false,
    };
  },
  methods: {
    handleRemoveDraft() {
      const { mergeRequestQueryVariables } = this;

      this.isMakingRequest = true;

      this.$apollo
        .mutate({
          mutation: removeDraftMutation,
          variables: {
            ...mergeRequestQueryVariables,
            draft: false,
          },
          update(
            store,
            {
              data: {
                mergeRequestSetDraft: {
                  errors,
                  mergeRequest: { mergeableDiscussionsState, draft, title },
                },
              },
            },
          ) {
            if (errors?.length) {
              createAlert({
                message: MSG_SOMETHING_WENT_WRONG,
              });

              return;
            }

            const sourceData = store.readQuery({
              query: getStateQuery,
              variables: mergeRequestQueryVariables,
            });

            const data = produce(sourceData, (draftState) => {
              draftState.project.mergeRequest.mergeableDiscussionsState = mergeableDiscussionsState;
              draftState.project.mergeRequest.draft = draft;
              draftState.project.mergeRequest.title = title;
            });

            store.writeQuery({
              query: getStateQuery,
              data,
              variables: mergeRequestQueryVariables,
            });
          },
          optimisticResponse: {
            // eslint-disable-next-line @gitlab/require-i18n-strings
            __typename: 'Mutation',
            mergeRequestSetDraft: {
              __typename: 'MergeRequestSetWipPayload',
              errors: [],
              mergeRequest: {
                __typename: 'MergeRequest',
                id: this.mr.issuableId,
                mergeableDiscussionsState: true,
                title: this.mr.title,
                draft: false,
              },
            },
          },
        })
        .then(
          ({
            data: {
              mergeRequestSetDraft: {
                mergeRequest: { title },
              },
            },
          }) => {
            MergeRequest.toggleDraftStatus(title, true);
          },
        )
        .catch(() =>
          createAlert({
            message: MSG_SOMETHING_WENT_WRONG,
          }),
        )
        .finally(() => {
          this.isMakingRequest = false;
        });
    },
  },
  i18n: {
    removeDraftStatus: s__(
      'mrWidget|%{boldStart}Merge blocked:%{boldEnd} Select %{boldStart}Mark as ready%{boldEnd} to remove it from Draft status.',
    ),
  },
  MSG_MARK_READY,
};
</script>

<template>
  <state-container
    status="failed"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <span
      class="gl-display-inline-flex gl-align-self-start gl-pt-2 gl-ml-0! gl-text-body! gl-flex-grow-1"
    >
      <bold-text :message="$options.i18n.removeDraftStatus" />
    </span>
    <template #actions>
      <gl-button
        v-if="userPermissions.updateMergeRequest"
        size="small"
        :disabled="isMakingRequest"
        :loading="isMakingRequest"
        variant="confirm"
        class="js-remove-draft gl-md-ml-3 gl-align-self-start"
        data-testid="removeWipButton"
        @click="handleRemoveDraft"
      >
        {{ $options.MSG_MARK_READY }}
      </gl-button>
    </template>
  </state-container>
</template>
