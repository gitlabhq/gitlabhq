<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import Stacktrace from '~/error_tracking/components/stacktrace.vue';
import service from '~/error_tracking/services';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';

export default {
  components: {
    GlLoadingIcon,
    Stacktrace,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    identifier: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      stackTraceData: {},
    };
  },
  computed: {
    stackTraceEntries() {
      return this.stackTraceData.stack_trace_entries?.toReversed() ?? [];
    },
    stackTracePath() {
      return `/${this.fullPath}/-/error_tracking/${this.identifier}/stack_trace.json`;
    },
  },
  mounted() {
    this.startPolling(this.stackTracePath);
  },
  beforeDestroy() {
    this.stackTracePoll?.stop();
  },
  methods: {
    startPolling(endpoint) {
      this.loading = true;

      this.stackTracePoll = new Poll({
        resource: service,
        method: 'getSentryData',
        data: { endpoint },
        successCallback: ({ data }) => {
          if (!data) {
            return;
          }

          this.stackTraceData = data.error;
          this.stackTracePoll.stop();
          this.loading = false;
        },
        errorCallback: () => {
          createAlert({ message: __('Failed to load stacktrace.') });
          this.loading = false;
        },
      });

      this.stackTracePoll.makeRequest();
    },
  },
};
</script>

<template>
  <div>
    <div :class="{ 'gl-border-b-0': loading }" class="card card-slim gl-mb-0 gl-mt-5">
      <div class="card-header gl-border-b-0">
        <h2 class="card-title gl-my-2 gl-text-base">{{ __('Stack trace') }}</h2>
      </div>
    </div>
    <div v-if="loading" class="card gl-mb-0">
      <gl-loading-icon class="gl-my-3" />
    </div>
    <stacktrace v-else :entries="stackTraceEntries" />
  </div>
</template>
