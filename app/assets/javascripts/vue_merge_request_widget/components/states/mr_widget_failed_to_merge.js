import statusIcon from '../mr_widget_status_icon.vue';
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
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <template v-if="isRefreshing">
        <status-icon status="loading" />
        <span class="media-body bold js-refresh-label">
          Refreshing now
        </span>
      </template>
      <template v-else>
        <status-icon status="warning" :show-disabled-button="true" />
        <div class="media-body space-children">
          <span class="bold">
            <span
              class="has-error-message"
              v-if="mr.mergeError">
              {{mr.mergeError}}.
            </span>
            <span v-else>Merge failed.</span>
            <span
              :class="{ 'has-custom-error': mr.mergeError }">
              Refreshing in {{timerText}} to show the updated status...
            </span>
          </span>
          <button
            @click="refresh"
            class="btn btn-default btn-xs js-refresh-button"
            type="button">
            Refresh now
          </button>
        </div>
      </template>
    </div>
  `,
};
