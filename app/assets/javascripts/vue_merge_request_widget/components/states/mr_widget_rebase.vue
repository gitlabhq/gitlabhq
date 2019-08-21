<script>
import { GlLoadingIcon } from '@gitlab/ui';
import simplePoll from '../../../lib/utils/simple_poll';
import eventHub from '../../event_hub';
import statusIcon from '../mr_widget_status_icon.vue';
import Flash from '../../../flash';
import { __, sprintf } from '~/locale';

export default {
  name: 'MRWidgetRebase',
  components: {
    statusIcon,
    GlLoadingIcon,
  },
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
      isMakingRequest: false,
      rebasingError: null,
    };
  },
  computed: {
    status() {
      if (this.mr.rebaseInProgress || this.isMakingRequest) {
        return 'loading';
      }
      if (!this.mr.canPushToSourceBranch && !this.mr.rebaseInProgress) {
        return 'warning';
      }
      return 'success';
    },
    showDisabledButton() {
      return ['failed', 'loading'].includes(this.status);
    },
    fastForwardMergeText() {
      return sprintf(
        __(
          `Fast-forward merge is not possible. Rebase the source branch onto %{startTag}${this.mr.targetBranch}%{endTag} to allow this merge request to be merged.`,
        ),
        {
          startTag: '<span class="label-branch">',
          endTag: '</span>',
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
        .catch(error => {
          this.rebasingError = error.merge_error;
          this.isMakingRequest = false;
          Flash(__('Something went wrong. Please try again.'));
        });
    },
    checkRebaseStatus(continuePolling, stopPolling) {
      this.service
        .poll()
        .then(res => res.data)
        .then(res => {
          if (res.rebase_in_progress) {
            continuePolling();
          } else {
            this.isMakingRequest = false;

            if (res.merge_error && res.merge_error.length) {
              this.rebasingError = res.merge_error;
              Flash(__('Something went wrong. Please try again.'));
            }

            eventHub.$emit('MRWidgetRebaseSuccess');
            stopPolling();
          }
        })
        .catch(() => {
          this.isMakingRequest = false;
          Flash(__('Something went wrong. Please try again.'));
          stopPolling();
        });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon :status="status" :show-disabled-button="showDisabledButton" />

    <div class="rebase-state-find-class-convention media media-body space-children">
      <template v-if="mr.rebaseInProgress || isMakingRequest">
        <span class="bold">{{ __('Rebase in progress') }}</span>
      </template>
      <template v-if="!mr.rebaseInProgress && !mr.canPushToSourceBranch">
        <span class="bold" v-html="fastForwardMergeText"></span>
      </template>
      <template v-if="!mr.rebaseInProgress && mr.canPushToSourceBranch && !isMakingRequest">
        <div
          class="accept-merge-holder clearfix js-toggle-container accept-action media space-children"
        >
          <button
            :disabled="isMakingRequest"
            type="button"
            class="btn btn-sm btn-reopen btn-success qa-mr-rebase-button"
            @click="rebase"
          >
            <gl-loading-icon v-if="isMakingRequest" />{{ __('Rebase') }}
          </button>
          <span v-if="!rebasingError" class="bold">{{
            __(
              'Fast-forward merge is not possible. Rebase the source branch onto the target branch or merge target branch into source branch to allow this merge request to be merged.',
            )
          }}</span>
          <span v-else class="bold danger">{{ rebasingError }}</span>
        </div>
      </template>
    </div>
  </div>
</template>
