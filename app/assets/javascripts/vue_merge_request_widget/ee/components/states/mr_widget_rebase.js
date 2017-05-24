/* global Flash */

import simplePoll from '~/lib/utils/simple_poll';
import eventHub from '../../../event_hub';

export default {
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
    };
  },
  computed: {
    isApprovalsLeft() {
      return this.mr.approvals && this.mr.approvalsLeft;
    },
  },
  methods: {
    rebase() {
      this.isMakingRequest = true;
      this.service.rebase().then(() => {
        simplePoll((continuePolling, stopPolling) => {
          this.service.poll()
            .then(res => res.json())
            .then((res) => {
              if (res.rebase_in_progress) {
                continuePolling();
              } else {
                this.isMakingRequest = false;
                eventHub.$emit('MRWidgetUpdateRequested');
                stopPolling();
              }
            })
            .catch(() => {
              this.isMakingRequest = false;
              new Flash('Something went wrong. Please try again.'); // eslint-disable-line
              stopPolling();
            });
        });
      }).catch(() => {
        this.isMakingRequest = false;
        new Flash('Something went wrong. Please try again.'); // eslint-disable-line
      });
    },
  },
  template: `
    <div class="mr-widget-body">
      <div class="rebase-state-find-class-convention">
        <template v-if="mr.rebaseInProgress || isMakingRequest">
          <button
            type="button"
            class="btn btn-success btn-small"
            disabled="true">
            Merge
          </button>
          <span class="bold">
            <i
              class="fa fa-spinner fa-spin"
              aria-hidden="true" />
            Rebase in progress. This merge request is in the process of being rebased.
          </span>
        </template>
        <template v-if="!mr.rebaseInProgress && !mr.canPushToSourceBranch">
          <button
            type="button"
            class="btn btn-success btn-small"
            disabled="true">
            Merge
          </button>
          <span class="bold">
            Fast-forward merge is not possible.
            Rebase the source branch onto
            <span class="label-branch">{{mr.targetBranch}}</span>
            to allow this merge request to be merged.
          </span>
        </template>
        <template v-if="!mr.rebaseInProgress && mr.canPushToSourceBranch && !isMakingRequest">
          <div class="accept-merge-holder clearfix js-toggle-container accept-action">
            <button
              class="btn btn-small btn-reopen btn-success"
              :disabled="isApprovalsLeft || isMakingRequest"
              @click="rebase">
              <i
                v-if="isMakingRequest"
                class="fa fa-spinner fa-spin"
                aria-hidden="true" />
              Rebase
            </button>
            <span class="bold">
              Fast-forward merge is not possible.
              Rebase the source branch onto the target branch or merge target
              branch into source branch to allow this merge request to be merged.
            </span>
          </div>
          <div class="mr-info-list">
            <div class="legend"></div>
            <p v-if="isApprovalsLeft">
              Rebasing is disabled until merge request has been approved.
            </p>
          </div>
        </template>
      </div>
    </div>
  `,
};
