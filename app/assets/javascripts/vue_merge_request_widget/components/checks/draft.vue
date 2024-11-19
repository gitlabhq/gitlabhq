<script>
import { produce } from 'immer';

import { createAlert } from '~/alert';
import MergeRequest from '~/merge_request';

import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';

import draftStateQuery from '../../queries/states/draft.query.graphql';
import removeDraftMutation from '../../queries/toggle_draft.mutation.graphql';

import ActionButtons from '../action_buttons.vue';
import MergeChecksMessage from './message.vue';

import { DRAFT_CHECK_READY, DRAFT_CHECK_ERROR } from './i18n';

export default {
  name: 'MergeChecksDraft',
  components: {
    MergeChecksMessage,
    ActionButtons,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    state: {
      query: draftStateQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data?.project?.mergeRequest,
    },
  },
  props: {
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    check: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: {},
      isMutating: false,
    };
  },
  computed: {
    networking() {
      return this.isLoading || this.isMutating;
    },
    isLoading() {
      return this.$apollo.queries.state.loading;
    },
    userCanUpdateMergeRequest() {
      return this.state.userPermissions.updateMergeRequest;
    },
    showTertiaryButton() {
      return !this.networking && this.userCanUpdateMergeRequest;
    },
    tertiaryActionsButtons() {
      return [
        {
          text: DRAFT_CHECK_READY,
          category: 'default',
          testId: 'mark-as-ready-button',
          onClick: () => this.removeDraft(),
        },
      ];
    },
  },
  methods: {
    removeDraft() {
      const { mergeRequestQueryVariables } = this;

      this.isMutating = true;

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
                message: DRAFT_CHECK_ERROR,
              });

              return;
            }

            const sourceData = store.readQuery({
              query: draftStateQuery,
              variables: mergeRequestQueryVariables,
            });

            const data = produce(sourceData, (draftState) => {
              draftState.project.mergeRequest.mergeableDiscussionsState = mergeableDiscussionsState;
              draftState.project.mergeRequest.draft = draft;
              draftState.project.mergeRequest.title = title;
            });

            store.writeQuery({
              query: draftStateQuery,
              data,
              variables: mergeRequestQueryVariables,
            });
          },
          optimisticResponse: {
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
            message: DRAFT_CHECK_ERROR,
          }),
        )
        .finally(() => {
          this.isMutating = false;
        });
    },
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template #failed>
      <action-buttons v-if="showTertiaryButton" :tertiary-buttons="tertiaryActionsButtons" />
    </template>
  </merge-checks-message>
</template>
