<script>
import { mapGetters } from 'vuex';
import IssuableTimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';

export default {
  components: {
    IssuableTimeTracker,
  },
  inject: ['timeTrackingLimitToHours'],
  computed: {
    ...mapGetters(['activeBoardItem']),
    initialTimeTracking() {
      const {
        timeEstimate,
        totalTimeSpent,
        humanTimeEstimate,
        humanTotalTimeSpent,
      } = this.activeBoardItem;
      return {
        timeEstimate,
        totalTimeSpent,
        humanTimeEstimate,
        humanTotalTimeSpent,
      };
    },
  },
};
</script>

<template>
  <issuable-time-tracker
    :issuable-id="activeBoardItem.id.toString()"
    :issuable-iid="activeBoardItem.iid.toString()"
    :limit-to-hours="timeTrackingLimitToHours"
    :initial-time-tracking="initialTimeTracking"
    :show-collapsed="false"
  />
</template>
