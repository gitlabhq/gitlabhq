<script>
import { stripHtml } from '~/lib/utils/text_utility';
import { sprintf, s__, n__ } from '~/locale';
import eventHub from '../../event_hub';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetFailedToMerge',

  components: {
    StateContainer,
  },

  props: {
    mr: {
      type: Object,
      required: true,
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
      const mergeError = this.prepareMergeError(this.mr.mergeError);

      return sprintf(
        s__('mrWidget|%{mergeError}.'),
        {
          mergeError,
        },
        false,
      );
    },
    timerText() {
      return n__(
        'Refreshing in a second to show the updated status...',
        'Refreshing in %d seconds to show the updated status...',
        this.timer,
      );
    },
    actions() {
      return [
        {
          text: s__('mrWidget|Refresh now'),
          onClick: () => this.refresh(),
        },
      ];
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
      this.timer -= 1;

      if (this.timer === 0) {
        this.refresh();
      }
    },
    prepareMergeError(mergeError) {
      return mergeError
        ? stripHtml(mergeError, ' ')
            .replace(/(\.$|\s+)/g, ' ')
            .trim()
        : '';
    },
  },
};
</script>
<template>
  <state-container
    v-if="isRefreshing"
    status="loading"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <span class="gl-font-bold">
      {{ s__('mrWidget|Refreshing now') }}
    </span>
  </state-container>
  <state-container
    v-else
    status="failed"
    :actions="actions"
    is-collapsible
    :collapsed="mr.mergeDetailsCollapsed"
    @toggle="() => mr.toggleMergeDetails()"
  >
    <span v-if="mr.mergeError" class="has-error-message gl-font-bold" data-testid="merge-error">
      {{ mergeError }}
    </span>
    <span v-else class="gl-font-bold"> {{ s__('mrWidget|Merge failed.') }} </span>
    <span :class="{ 'has-custom-error': mr.mergeError }"> {{ timerText }} </span>
  </state-container>
</template>
