<script>
import { GlButton } from '@gitlab/ui';
import { produce } from 'immer';
import { createAlert } from '~/flash';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import getStateQuery from '../../queries/get_state.query.graphql';
import draftQuery from '../../queries/states/draft.query.graphql';
import removeDraftMutation from '../../queries/toggle_draft.mutation.graphql';
import StateContainer from '../state_container.vue';
import eventHub from '../../event_hub';

export default {
  name: 'WorkInProgress',
  components: {
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
      update: (data) => data.project.mergeRequest.userPermissions,
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
                message: __('Something went wrong. Please try again.'),
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
            toast(__('Marked as ready. Merging is now allowed.'));
            document.querySelector(
              '.merge-request .detail-page-description .title',
            ).textContent = title;

            if (!window.gon?.features?.realtimeMrStatusChange) {
              eventHub.$emit('MRWidgetUpdateRequested');
            }
          },
        )
        .catch(() =>
          createAlert({
            message: __('Something went wrong. Please try again.'),
          }),
        )
        .finally(() => {
          this.isMakingRequest = false;
        });
    },
  },
};
</script>

<template>
  <state-container :mr="mr" status="failed">
    <span class="gl-font-weight-bold gl-ml-0! gl-text-body! gl-flex-grow-1">
      {{ __("Merge blocked: merge request must be marked as ready. It's still marked as draft.") }}
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
        {{ s__('mrWidget|Mark as ready') }}
      </gl-button>
    </template>
  </state-container>
</template>
