import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetFailedToMerge',
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      timer: 10,
      isRefreshing: false,
    };
  },
  mounted() {
    setInterval(() => {
      this.updateTimer();
    }, 1000);
  },
  created() {
    eventHub.$emit('DisablePolling');
  },
  computed: {
    timerText() {
      return this.timer > 1 ? `${this.timer} seconds` : 'a second';
    },
  },
  methods: {
    refresh() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested');
      eventHub.$emit('EnablePolling');
    },
    updateTimer() {
      this.timer = this.timer - 1;

      if (this.timer === 0) {
        this.refresh();
      }
    },
  },
  template: `
    <div class="mr-widget-body">
      <button
        class="btn btn-success btn-small"
        disabled="true"
        type="button">
        Merge
      </button>
      <span
        v-if="!isRefreshing"
        class="bold danger">
        <span v-if="mr.mergeError">{{mr.mergeError}}</span>
        <span v-else>Merge failed.</span>
        <span
          :class="{ 'has-custom-error': mr.mergeError }">
          Refreshing in {{timerText}} to show the updated status...
        </span>
        <button
          @click="refresh"
          class="btn btn-default btn-xs js-refresh-button"
          type="button">
          Refresh now
        </button>
      </span>
      <span
        v-if="isRefreshing"
        class="bold js-refresh-label">
        Refreshing now...
      </span>
    </div>
  `,
};
