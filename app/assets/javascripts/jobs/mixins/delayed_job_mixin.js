import { calculateRemainingMilliseconds, formatTime } from '~/lib/utils/datetime_utility';

export default {
  data() {
    return {
      remainingTime: formatTime(0),
      remainingTimeIntervalId: null,
    };
  },

  mounted() {
    this.startRemainingTimeInterval();
  },

  beforeDestroy() {
    if (this.remainingTimeIntervalId) {
      clearInterval(this.remainingTimeIntervalId);
    }
  },

  computed: {
    isDelayedJob() {
      return this.job && this.job.scheduled;
    },
  },

  watch: {
    isDelayedJob() {
      this.startRemainingTimeInterval();
    },
  },

  methods: {
    startRemainingTimeInterval() {
      if (this.remainingTimeIntervalId) {
        clearInterval(this.remainingTimeIntervalId);
      }

      if (this.isDelayedJob) {
        this.updateRemainingTime();
        this.remainingTimeIntervalId = setInterval(() => this.updateRemainingTime(), 1000);
      }
    },

    updateRemainingTime() {
      const remainingMilliseconds = calculateRemainingMilliseconds(this.job.scheduled_at);
      this.remainingTime = formatTime(remainingMilliseconds);
    },
  },
};
