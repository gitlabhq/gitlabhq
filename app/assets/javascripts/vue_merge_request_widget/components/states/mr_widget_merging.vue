<script>
import { STATUS_MERGED } from '~/issues/constants';
import simplePoll from '~/lib/utils/simple_poll';
import MergeRequest from '~/merge_request';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import eventHub from '../../event_hub';
import { MERGE_ACTIVE_STATUS_PHRASES, STATE_MACHINE } from '../../constants';
import StatusIcon from '../mr_widget_status_icon.vue';

const { transitions } = STATE_MACHINE;
const { MERGE_FAILURE } = transitions;

export default {
  name: 'MRWidgetMerging',
  components: {
    BoldText,
    StatusIcon,
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
    const statusCount = MERGE_ACTIVE_STATUS_PHRASES.length;

    return {
      mergeStatus: MERGE_ACTIVE_STATUS_PHRASES[Math.floor(Math.random() * statusCount)],
    };
  },
  mounted() {
    this.initiateMergePolling();
  },
  methods: {
    initiateMergePolling() {
      simplePoll(
        (continuePolling, stopPolling) => {
          this.handleMergePolling(continuePolling, stopPolling);
        },
        { timeout: 0 },
      );
    },
    handleMergePolling(continuePolling, stopPolling) {
      this.service
        .poll()
        .then((res) => res.data)
        .then((data) => {
          if (data.state === STATUS_MERGED) {
            // If state is merged we should update the widget and stop the polling
            eventHub.$emit('MRWidgetUpdateRequested');
            eventHub.$emit('FetchActionsContent');
            MergeRequest.decreaseCounter();
            stopPolling();

            fetchUserCounts();

            // If user checked remove source branch and we didn't remove the branch yet
            // we should start another polling for source branch remove process
            if (this.removeSourceBranch && data.source_branch_exists) {
              this.initiateRemoveSourceBranchPolling();
            }
          } else if (data.merge_error) {
            eventHub.$emit('FailedToMerge', data.merge_error);
            this.mr.transitionStateMachine({ transition: MERGE_FAILURE });
            stopPolling();
          } else {
            // MR is not merged yet, continue polling until the state becomes 'merged'
            continuePolling();
          }
        })
        .catch(() => {
          this.mr.transitionStateMachine({ transition: MERGE_FAILURE });
          stopPolling();
        });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body mr-state-locked media">
    <status-icon status="loading" />
    <div class="media-body" data-testid="merging-state">
      <bold-text :message="mergeStatus.message" />
      <gl-emoji :data-name="mergeStatus.emoji" />
    </div>
  </div>
</template>
