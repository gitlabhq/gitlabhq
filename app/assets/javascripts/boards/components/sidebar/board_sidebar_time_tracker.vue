<script>
import { mapGetters } from 'vuex';
import IssuableTimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';

export default {
  components: {
    IssuableTimeTracker,
  },
  inject: ['timeTrackingLimitToHours'],
  computed: {
    ...mapGetters(['activeIssue']),
  },
};
</script>

<template>
  <issuable-time-tracker
    :time-estimate="activeIssue.timeEstimate"
    :time-spent="activeIssue.totalTimeSpent"
    :human-time-estimate="activeIssue.humanTimeEstimate"
    :human-time-spent="activeIssue.humanTotalTimeSpent"
    :limit-to-hours="timeTrackingLimitToHours"
    :show-collapsed="false"
  />
</template>
