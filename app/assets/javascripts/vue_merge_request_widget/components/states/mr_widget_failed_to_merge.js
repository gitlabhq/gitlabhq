import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetFailedToMerge',
  data() {
    return {
      timer: 10,
      isRefreshing: false,
    }
  },
  mounted() {
    setInterval(() => {
      this.updateTimer();
    }, 1000);
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
      <button class="btn btn-success btn-small" disabled="true" type="button">Merge</button>
      <span
        v-if="!isRefreshing"
        class="bold danger">
        Merge failed. Refreshing in {{timerText}} to show the updated status...
        <button
          @click="refresh"
          class="btn btn-default btn-xs js-refresh-button"
        >Refresh now</button>
      </span>
      <span
        v-if="isRefreshing"
        class="bold js-refresh-label">Refreshing now...</span>
    </div>
  `,
};
