<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { mergeUrlParams } from '~/lib/utils/url_utility';

import { s__ } from '~/locale';
import AddRequest from './add_request.vue';
import DetailedMetric from './detailed_metric.vue';
import InfoApp from './info_modal/info_app.vue';
import RequestSelector from './request_selector.vue';

export default {
  components: {
    AddRequest,
    DetailedMetric,
    GlLink,
    InfoApp,
    RequestSelector,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    store: {
      type: Object,
      required: true,
    },
    env: {
      type: String,
      required: true,
    },
    requestId: {
      type: String,
      required: true,
    },
    requestMethod: {
      type: String,
      required: true,
    },
    peekUrl: {
      type: String,
      required: true,
    },
    statsUrl: {
      type: String,
      required: true,
    },
  },
  detailedMetrics: [
    {
      metric: 'active-record',
      title: 'pg',
      header: s__('PerformanceBar|SQL queries'),
      keys: ['sql', 'cached', 'transaction', 'db_role', 'db_config_name'],
    },
    {
      metric: 'bullet',
      header: s__('PerformanceBar|Bullet notifications'),
      keys: ['notification'],
    },
    {
      metric: 'gitaly',
      header: s__('PerformanceBar|Gitaly calls'),
      keys: ['feature', 'request'],
    },
    {
      metric: 'redis',
      header: s__('PerformanceBar|Redis calls'),
      keys: ['cmd', 'instance'],
    },
    {
      metric: 'es',
      header: s__('PerformanceBar|Elasticsearch calls'),
      keys: ['request', 'body'],
    },
    {
      metric: 'zkt',
      header: s__('PerformanceBar|Zoekt calls'),
      keys: ['request', 'body'],
    },
    {
      metric: 'ch',
      header: s__('PerformanceBar|ClickHouse queries'),
      keys: ['sql', 'database', 'statistics'],
    },
    {
      metric: 'external-http',
      title: 'external',
      header: s__('PerformanceBar|External Http calls'),
      keys: ['label', 'code', 'proxy', 'error'],
    },
    {
      metric: 'memory',
      header: s__('PerformanceBar|Memory'),
      keys: ['item_header', 'item_content'],
    },
    {
      metric: 'total',
      header: s__('PerformanceBar|Frontend resources'),
      keys: ['name', 'size'],
    },
  ],
  data() {
    return { currentRequestId: '' };
  },
  computed: {
    requests() {
      return this.store.requestsWithDetails();
    },
    currentRequest: {
      get() {
        return this.store.findRequest(this.currentRequestId);
      },
      set(requestId) {
        this.currentRequestId = requestId;
      },
    },
    downloadPath() {
      const data = JSON.stringify(this.requests);
      const blob = new Blob([data], { type: 'text/plain' });
      return window.URL.createObjectURL(blob);
    },
    downloadName() {
      const fileName = this.requests[0].displayName;
      return `${fileName}_perf_bar_${Date.now()}.json`;
    },
    showZoekt() {
      return document.body.dataset.page === 'search:show';
    },
    showFlamegraphButtons() {
      return this.isGetRequest(this.currentRequestId);
    },
    showMemoryReportButton() {
      return this.isGetRequest(this.currentRequestId) && this.env === 'development';
    },
    memoryReportPath() {
      return mergeUrlParams(
        { performance_bar: 'memory' },
        this.store.findRequest(this.currentRequestId).fullUrl,
      );
    },
  },
  created() {
    if (!this.showZoekt) {
      this.$options.detailedMetrics = this.$options.detailedMetrics.filter(
        (item) => item.metric !== 'zkt',
      );
    }
  },
  mounted() {
    this.currentRequest = this.requestId;
  },
  methods: {
    changeCurrentRequest(newRequestId) {
      this.currentRequest = newRequestId;
      this.$emit('change-request', newRequestId);
    },
    flamegraphPath(mode, requestId) {
      return mergeUrlParams(
        { performance_bar: 'flamegraph', stackprof_mode: mode },
        this.store.findRequest(requestId).fullUrl,
      );
    },
    isGetRequest(requestId) {
      return this.store.findRequest(requestId)?.method?.toUpperCase() === 'GET';
    },
  },
};
</script>
<template>
  <div id="js-peek" :class="env">
    <div
      v-if="currentRequest"
      class="container-fluid gl-flex gl-overflow-x-auto"
      data-testid="performance-bar"
    >
      <div class="view-performance-container gl-flex gl-shrink-0">
        <info-app :current-request="currentRequest" />
        <detailed-metric
          v-for="metric in $options.detailedMetrics"
          :key="metric.metric"
          :current-request="currentRequest"
          :metric="metric.metric"
          :title="metric.title"
          :header="metric.header"
          :keys="metric.keys"
        />
        <div
          v-if="currentRequest.details && currentRequest.details.tracing"
          id="peek-view-trace"
          class="view"
        >
          <gl-link class="gl-underline" :href="currentRequest.details.tracing.tracing_url">{{
            s__('PerformanceBar|Trace')
          }}</gl-link>
        </div>
        <div v-if="showFlamegraphButtons" id="peek-flamegraph" class="view">
          <gl-link
            v-gl-tooltip.viewport
            class="gl-text-sm"
            :href="flamegraphPath('wall', currentRequestId)"
            :title="s__('PerformanceBar|Wall flamegraph')"
            >{{ s__('PerformanceBar|Wall') }}</gl-link
          >
          /
          <gl-link
            v-gl-tooltip.viewport
            class="gl-text-sm"
            :href="flamegraphPath('cpu', currentRequestId)"
            :title="s__('PerformanceBar|CPU flamegraph')"
            >{{ s__('PerformanceBar|CPU') }}</gl-link
          >
          /
          <gl-link
            v-gl-tooltip.viewport
            class="gl-text-sm"
            :href="flamegraphPath('object', currentRequestId)"
            :title="s__('PerformanceBar|Object flamegraph')"
            >{{ s__('PerformanceBar|Object') }}</gl-link
          >
          <span class="gl-opacity-7">{{ s__('PerformanceBar|flamegraph') }}</span>
        </div>
      </div>
      <div class="gl-ml-auto gl-flex gl-shrink-0">
        <div class="view-reports-container gl-flex">
          <gl-link
            v-if="currentRequest.details"
            id="peek-download"
            v-gl-tooltip.viewport
            class="view gl-text-sm"
            is-unsafe-link
            :download="downloadName"
            :href="downloadPath"
            :title="s__('PerformanceBar|Download report')"
            >{{ s__('PerformanceBar|Download') }}</gl-link
          >
          <gl-link
            v-if="showMemoryReportButton"
            id="peek-memory-report"
            v-gl-tooltip.viewport
            class="view gl-text-sm"
            :href="memoryReportPath"
            :title="s__('PerformanceBar|Download memory report')"
            >{{ s__('PerformanceBar|Memory report') }}</gl-link
          >
          <gl-link
            v-if="statsUrl"
            v-gl-tooltip.viewport
            class="view gl-text-sm"
            :href="statsUrl"
            :title="s__('PerformanceBar|Show stats')"
            >{{ s__('PerformanceBar|Stats') }}</gl-link
          >
        </div>
        <request-selector
          v-if="currentRequest"
          :current-request="currentRequest"
          :requests="requests"
          @change-current-request="changeCurrentRequest"
        />
        <add-request v-on="$listeners" />
      </div>
    </div>
  </div>
</template>
