<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import TracingEmptyState from './tracing_empty_state.vue';
import TracingTableList from './tracing_table_list.vue';

export default {
  components: {
    GlLoadingIcon,
    TracingTableList,
    TracingEmptyState,
  },
  props: {
    observabilityClient: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      loading: true,
      /**
       * tracingEnabled: boolean | null.
       * null identifies a state where we don't know if tracing is enabled or not (e.g. when fetching the status from the API fails)
       */
      tracingEnabled: null,
      traces: [],
    };
  },
  created() {
    this.checkEnabled();
  },
  methods: {
    async checkEnabled() {
      this.loading = true;
      try {
        this.tracingEnabled = await this.observabilityClient.isTracingEnabled();
        if (this.tracingEnabled) {
          await this.fetchTraces();
        }
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to load page.'),
        });
      } finally {
        this.loading = false;
      }
    },
    async enableTracing() {
      this.loading = true;
      try {
        await this.observabilityClient.enableTraces();
        this.tracingEnabled = true;
        await this.fetchTraces();
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to enable tracing.'),
        });
      } finally {
        this.loading = false;
      }
    },
    async fetchTraces() {
      this.loading = true;
      try {
        const traces = await this.observabilityClient.fetchTraces();
        this.traces = traces;
      } catch (e) {
        createAlert({
          message: s__('Tracing|Failed to load traces.'),
        });
      } finally {
        this.loading = false;
      }
    },
    selectTrace(trace) {
      visitUrl(joinPaths(window.location.pathname, trace.trace_id));
    },
  },
};
</script>

<template>
  <div>
    <div v-if="loading" class="gl-py-5">
      <gl-loading-icon size="lg" />
    </div>

    <template v-else-if="tracingEnabled !== null">
      <tracing-empty-state v-if="tracingEnabled === false" :enable-tracing="enableTracing" />

      <tracing-table-list
        v-else
        :traces="traces"
        @reload="fetchTraces"
        @trace-selected="selectTrace"
      />
    </template>
  </div>
</template>
