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
      this.timer = this.timer - 1;
      if (this.timer === 0) {
        this.refresh();
      }
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
  },
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small" disabled="true" type="button">Merge</button>
      <span class="bold danger" v-if="!isRefreshing">
        Merge failed. Refreshing in {{timerText}} to show the updated status...
        <button
          @click="refresh"
          class="btn btn-default btn-xs"
        >Refresh now</button>
      </span>
      <span class="bold" v-if="isRefreshing">Refreshing now...</span>
    </div>
  `,
};
