<script>
import { GlButton } from '@gitlab/ui';
import { produce } from 'immer';
import $ from 'jquery';
import createFlash from '~/flash';
import toast from '~/vue_shared/plugins/global_toast';
import { __ } from '~/locale';
import MergeRequest from '~/merge_request';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import getStateQuery from '../../queries/get_state.query.graphql';
import draftQuery from '../../queries/states/draft.query.graphql';
import removeDraftMutation from '../../queries/toggle_draft.mutation.graphql';
import StatusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'WorkInProgress',
  components: {
    StatusIcon,
    GlButton,
  },
  mixins: [glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  apollo: {
    userPermissions: {
      query: draftQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest.userPermissions,
    },
  },
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      userPermissions: {},
      isMakingRequest: false,
    };
  },
  computed: {
    canUpdate() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.userPermissions.updateMergeRequest;
      }

      return Boolean(this.mr.removeWIPPath);
    },
  },
  methods: {
    removeDraftMutation() {
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
              createFlash({
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
            $('.merge-request .detail-page-description .title').text(title);
            eventHub.$emit('MRWidgetUpdateRequested');
          },
        )
        .catch(() =>
          createFlash({
            message: __('Something went wrong. Please try again.'),
          }),
        )
        .finally(() => {
          this.isMakingRequest = false;
        });
    },
    handleRemoveDraft() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        this.removeDraftMutation();
      } else {
        this.isMakingRequest = true;
        this.service
          .removeWIP()
          .then((res) => res.data)
          .then((data) => {
            eventHub.$emit('UpdateWidgetData', data);
            MergeRequest.toggleDraftStatus(this.mr.title, true);
          })
          .catch(() => {
            this.isMakingRequest = false;
            createFlash({
              message: __('Something went wrong. Please try again.'),
            });
          });
      }
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="canUpdate" status="warning" />
    <div class="media-body">
      <div class="float-left">
        <span class="gl-ml-0! gl-text-body! gl-font-weight-bold">
          {{
            __("Merge blocked: merge request must be marked as ready. It's still marked as draft.")
          }}
        </span>
      </div>
      <gl-button
        v-if="canUpdate"
        size="small"
        :disabled="isMakingRequest"
        :loading="isMakingRequest"
        class="js-remove-draft gl-ml-3"
        @click="handleRemoveDraft"
      >
        {{ s__('mrWidget|Mark as ready') }}
      </gl-button>
    </div>
  </div>
</template>
