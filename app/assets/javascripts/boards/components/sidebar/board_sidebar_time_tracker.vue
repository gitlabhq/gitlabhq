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
  },
};
</script>

<template>
  <issuable-time-tracker
    :time-estimate="activeBoardItem.timeEstimate"
    :time-spent="activeBoardItem.totalTimeSpent"
    :human-time-estimate="activeBoardItem.humanTimeEstimate"
    :human-time-spent="activeBoardItem.humanTotalTimeSpent"
    :limit-to-hours="timeTrackingLimitToHours"
    :show-collapsed="false"
  />
</template>
