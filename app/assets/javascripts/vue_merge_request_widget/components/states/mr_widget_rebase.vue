<script>
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import { createAlert } from '~/flash';
import { __ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import simplePoll from '~/lib/utils/simple_poll';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import rebaseQuery from '../../queries/states/rebase.query.graphql';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetRebase',
  apollo: {
    state: {
      query: rebaseQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest,
    },
  },
  components: {
    GlSkeletonLoader,
    GlButton,
    StateContainer,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: {},
      isMakingRequest: false,
      rebasingError: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.state.loading;
    },
    rebaseInProgress() {
      return this.state.rebaseInProgress;
    },
    canPushToSourceBranch() {
      return this.state.userPermissions.pushToSourceBranch;
    },
    targetBranch() {
      return this.state.targetBranch;
    },
    status() {
      if (this.isLoading) {
        return undefined;
      }

      if (this.rebaseInProgress || this.isMakingRequest) {
        return 'loading';
      }
      if (!this.canPushToSourceBranch && !this.rebaseInProgress) {
        return 'failed';
      }
      return 'success';
    },
    fastForwardMergeText() {
      return __('Merge blocked: the source branch must be rebased onto the target branch.');
    },
    showRebaseWithoutPipeline() {
      return (
        !this.mr.onlyAllowMergeIfPipelineSucceeds ||
        (this.mr.onlyAllowMergeIfPipelineSucceeds && this.mr.allowMergeOnSkippedPipeline)
      );
    },
  },
  methods: {
    rebase({ skipCi = false } = {}) {
      this.isMakingRequest = true;
      this.rebasingError = null;

      this.service
        .rebase({ skipCi })
        .then(() => {
          simplePoll(this.checkRebaseStatus);
        })
        .catch((error) => {
          this.isMakingRequest = false;

          if (error.response && error.response.data && error.response.data.merge_error) {
            this.rebasingError = error.response.data.merge_error;
          } else {
            createAlert({
              message: __('Something went wrong. Please try again.'),
            });
          }
        });
    },
    rebaseWithoutCi() {
      return this.rebase({ skipCi: true });
    },
    checkRebaseStatus(continuePolling, stopPolling) {
      this.service
        .poll()
        .then((res) => res.data)
        .then((res) => {
          if (res.rebase_in_progress || res.should_be_rebased) {
            continuePolling();
          } else {
            this.isMakingRequest = false;

            if (res.merge_error && res.merge_error.length) {
              this.rebasingError = res.merge_error;
            } else {
              toast(__('Rebase completed'));
            }

            eventHub.$emit('MRWidgetRebaseSuccess');
            stopPolling();
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
          stopPolling();
        });
    },
  },
};
</script>
<template>
  <state-container :mr="mr" :status="status" :is-loading="isLoading">
    <template #loading>
      <gl-skeleton-loader :width="334" :height="30">
        <rect x="0" y="3" width="24" height="24" rx="4" />
        <rect x="32" y="5" width="302" height="20" rx="4" />
      </gl-skeleton-loader>
    </template>
    <template v-if="!isLoading">
      <span
        v-if="rebaseInProgress || isMakingRequest"
        class="gl-ml-0! gl-text-body! gl-font-weight-bold"
        data-testid="rebase-message"
        >{{ __('Rebase in progress') }}</span
      >
      <span
        v-if="!rebaseInProgress && !canPushToSourceBranch"
        class="gl-text-body! gl-font-weight-bold gl-ml-0!"
        data-testid="rebase-message"
        >{{ fastForwardMergeText }}</span
      >
      <div
        v-if="!rebaseInProgress && canPushToSourceBranch && !isMakingRequest"
        class="accept-merge-holder clearfix js-toggle-container media gl-md-display-flex gl-flex-wrap gl-flex-grow-1"
      >
        <span
          v-if="!rebasingError"
          class="gl-font-weight-bold gl-w-100 gl-md-w-auto gl-flex-grow-1 gl-ml-0! gl-text-body! gl-md-mr-3"
          data-testid="rebase-message"
          data-qa-selector="no_fast_forward_message_content"
          >{{
            __('Merge blocked: the source branch must be rebased onto the target branch.')
          }}</span
        >
        <span
          v-else
          class="gl-font-weight-bold danger gl-w-100 gl-md-w-auto gl-flex-grow-1 gl-md-mr-3"
          data-testid="rebase-message"
          >{{ rebasingError }}</span
        >
      </div>
    </template>
    <template v-if="!isLoading" #actions>
      <gl-button
        :loading="isMakingRequest"
        variant="confirm"
        size="small"
        data-qa-selector="mr_rebase_button"
        data-testid="standard-rebase-button"
        class="gl-align-self-start"
        @click="rebase"
      >
        {{ __('Rebase') }}
      </gl-button>
      <gl-button
        v-if="showRebaseWithoutPipeline"
        :loading="isMakingRequest"
        variant="confirm"
        size="small"
        category="secondary"
        data-testid="rebase-without-ci-button"
        class="gl-align-self-start gl-mr-2"
        @click="rebaseWithoutCi"
      >
        {{ __('Rebase without pipeline') }}
      </gl-button>
    </template>
  </state-container>
</template>
