<script>
/* eslint-disable vue/no-v-html */
import { GlButton } from '@gitlab/ui';
import { escape } from 'lodash';
import simplePoll from '../../../lib/utils/simple_poll';
import eventHub from '../../event_hub';
import statusIcon from '../mr_widget_status_icon.vue';
import { deprecatedCreateFlash as Flash } from '../../../flash';
import { __, sprintf } from '~/locale';

export default {
  name: 'MRWidgetRebase',
  components: {
    statusIcon,
    GlButton,
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
          'Fast-forward merge is not possible. Rebase the source branch onto %{targetBranch} to allow this merge request to be merged.',
        ),
        {
          targetBranch: `<span class="label-branch">${escape(this.mr.targetBranch)}</span>`,
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
          this.isMakingRequest = false;

          if (error.response && error.response.data && error.response.data.merge_error) {
            this.rebasingError = error.response.data.merge_error;
          } else {
            Flash(__('Something went wrong. Please try again.'));
          }
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
        <span class="bold" data-testid="rebase-message">{{ __('Rebase in progress') }}</span>
      </template>
      <template v-if="!mr.rebaseInProgress && !mr.canPushToSourceBranch">
        <span class="bold" data-testid="rebase-message" v-html="fastForwardMergeText"></span>
      </template>
      <template v-if="!mr.rebaseInProgress && mr.canPushToSourceBranch && !isMakingRequest">
        <div
          class="accept-merge-holder clearfix js-toggle-container accept-action media space-children"
        >
          <gl-button
            :loading="isMakingRequest"
            variant="success"
            class="qa-mr-rebase-button"
            @click="rebase"
          >
            {{ __('Rebase') }}
          </gl-button>
          <span v-if="!rebasingError" class="bold" data-testid="rebase-message">{{
            __(
              'Fast-forward merge is not possible. Rebase the source branch onto the target branch.',
            )
          }}</span>
          <span v-else class="bold danger" data-testid="rebase-message">{{ rebasingError }}</span>
        </div>
      </template>
    </div>
  </div>
</template>
