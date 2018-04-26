<script>
import { n__ } from '~/locale';
import statusIcon from '../mr_widget_status_icon.vue';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetFailedToMerge',

  components: {
    statusIcon,
  },

  props: {
    mr: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },

  data() {
    return {
      timer: 10,
      isRefreshing: false,
    };
  },

  computed: {
    timerText() {
      return n__(
        'Refreshing in a second to show the updated status...',
        'Refreshing in %d seconds to show the updated status...',
        this.timer,
      );
    },
  },

  mounted() {
    setInterval(() => {
      this.updateTimer();
    }, 1000);
  },

  created() {
    eventHub.$emit('DisablePolling');
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
};
</script>
<template>
  <div class="mr-widget-body media">
    <template v-if="isRefreshing">
      <status-icon status="loading" />
      <span class="media-body bold js-refresh-label">
        {{ s__("mrWidget|Refreshing now") }}
      </span>
    </template>
    <template v-else>
      <status-icon
        status="warning"
        :show-disabled-button="true"
      />
      <div class="media-body space-children">
        <span class="bold">
          <span
            class="has-error-message"
            v-if="mr.mergeError"
          >
            {{ mr.mergeError }}.
          </span>
          <span v-else>
            {{ s__("mrWidget|Merge failed.") }}
          </span>
          <span
            :class="{ 'has-custom-error': mr.mergeError }"
          >
            {{ timerText }}
          </span>
        </span>
        <button
          @click="refresh"
          class="btn btn-default btn-xs js-refresh-button"
          type="button"
        >
          {{ s__("mrWidget|Refresh now") }}
        </button>
      </div>
    </template>
  </div>
</template>
