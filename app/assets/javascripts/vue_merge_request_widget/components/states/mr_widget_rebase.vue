<script>
/* eslint-disable vue/no-v-html */
import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import { escape } from 'lodash';
import createFlash from '~/flash';
import { __, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import simplePoll from '../../../lib/utils/simple_poll';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import rebaseQuery from '../../queries/states/rebase.query.graphql';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetRebase',
  apollo: {
    state: {
      query: rebaseQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project.mergeRequest,
    },
  },
  components: {
    statusIcon,
    GlButton,
    GlSkeletonLoader,
  },
  mixins: [glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
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
      return this.glFeatures.mergeRequestWidgetGraphql && this.$apollo.queries.state.loading;
    },
    rebaseInProgress() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.rebaseInProgress;
      }

      return this.mr.rebaseInProgress;
    },
    canPushToSourceBranch() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.userPermissions.pushToSourceBranch;
      }

      return this.mr.canPushToSourceBranch;
    },
    targetBranch() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.targetBranch;
      }

      return this.mr.targetBranch;
    },
    status() {
      if (this.rebaseInProgress || this.isMakingRequest) {
        return 'loading';
      }
      if (!this.canPushToSourceBranch && !this.rebaseInProgress) {
        return 'warning';
      }
      return 'success';
    },
    showDisabledButton() {
      return ['failed', 'loading'].includes(this.status);
    },
    fastForwardMergeText() {
      return sprintf(
        __('Merge blocked: the source branch must be rebased onto the target branch.'),
        {
          targetBranch: `<span class="label-branch">${escape(this.targetBranch)}</span>`,
        },
        false,
      );
    },
  },
  methods: {
    rebase() {
      this.isMakingRequest = true;
      this.rebasingError = null;

      this.service
        .rebase()
        .then(() => {
          simplePoll(this.checkRebaseStatus);
        })
        .catch((error) => {
          this.isMakingRequest = false;

          if (error.response && error.response.data && error.response.data.merge_error) {
            this.rebasingError = error.response.data.merge_error;
          } else {
            createFlash({
              message: __('Something went wrong. Please try again.'),
            });
          }
        });
    },
    checkRebaseStatus(continuePolling, stopPolling) {
      this.service
        .poll()
        .then((res) => res.data)
        .then((res) => {
          if (res.rebase_in_progress) {
            continuePolling();
          } else {
            this.isMakingRequest = false;

            if (res.merge_error && res.merge_error.length) {
              this.rebasingError = res.merge_error;
              createFlash({
                message: __('Something went wrong. Please try again.'),
              });
            }

            eventHub.$emit('MRWidgetRebaseSuccess');
            stopPolling();
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
          stopPolling();
        });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div v-if="isLoading" class="gl-w-full mr-conflict-loader">
      <gl-skeleton-loader :width="334" :height="30">
        <rect x="0" y="3" width="24" height="24" rx="4" />
        <rect x="32" y="5" width="302" height="20" rx="4" />
      </gl-skeleton-loader>
    </div>
    <template v-else>
      <status-icon :status="status" :show-disabled-button="showDisabledButton" />

      <div class="rebase-state-find-class-convention media media-body space-children">
        <span
          v-if="rebaseInProgress || isMakingRequest"
          class="gl-font-weight-bold"
          data-testid="rebase-message"
          >{{ __('Rebase in progress') }}</span
        >
        <span
          v-if="!rebaseInProgress && !canPushToSourceBranch"
          class="gl-font-weight-bold gl-ml-0!"
          data-testid="rebase-message"
          v-html="fastForwardMergeText"
        ></span>
        <div
          v-if="!rebaseInProgress && canPushToSourceBranch && !isMakingRequest"
          class="accept-merge-holder clearfix js-toggle-container accept-action media space-children"
        >
          <gl-button
            :loading="isMakingRequest"
            variant="confirm"
            data-qa-selector="mr_rebase_button"
            @click="rebase"
          >
            {{ __('Rebase') }}
          </gl-button>
          <span
            v-if="!rebasingError"
            class="gl-font-weight-bold"
            data-testid="rebase-message"
            data-qa-selector="no_fast_forward_message_content"
            >{{
              __('Merge blocked: the source branch must be rebased onto the target branch.')
            }}</span
          >
          <span v-else class="gl-font-weight-bold danger" data-testid="rebase-message">{{
            rebasingError
          }}</span>
        </div>
      </div>
    </template>
  </div>
</template>
