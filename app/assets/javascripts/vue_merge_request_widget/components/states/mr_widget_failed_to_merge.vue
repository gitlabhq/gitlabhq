<script>
import { n__ } from '~/locale';
import { stripHtml } from '~/lib/utils/text_utility';
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
      intervalId: null,
    };
  },

  computed: {
    mergeError() {
      return this.mr.mergeError ? stripHtml(this.mr.mergeError, ' ').trim() : '';
    },
    timerText() {
      return n__(
        'Refreshing in a second to show the updated status...',
        'Refreshing in %d seconds to show the updated status...',
        this.timer,
      );
    },
  },

  mounted() {
    this.intervalId = setInterval(this.updateTimer, 1000);
  },

  created() {
    eventHub.$emit('DisablePolling');
  },

  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
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
      <span class="media-body bold js-refresh-label"> {{ s__('mrWidget|Refreshing now') }} </span>
    </template>
    <template v-else>
      <status-icon :show-disabled-button="true" status="warning" />
      <div class="media-body space-children">
        <span class="bold">
          <span v-if="mr.mergeError" class="has-error-message"> {{ mergeError }} </span>
          <span v-else> {{ s__('mrWidget|Merge failed.') }} </span>
          <span :class="{ 'has-custom-error': mr.mergeError }"> {{ timerText }} </span>
        </span>
        <button
          class="btn btn-default btn-sm js-refresh-button"
          data-qa-selector="merge_request_error_content"
          type="button"
          @click="refresh"
        >
          {{ s__('mrWidget|Refresh now') }}
        </button>
      </div>
    </template>
  </div>
</template>
