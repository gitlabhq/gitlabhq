<script>
/* eslint-disable vue/no-v-html */
import { glEmojiTag } from '~/emoji';

import { s__ } from '~/locale';
import AddRequest from './add_request.vue';
import DetailedMetric from './detailed_metric.vue';
import RequestSelector from './request_selector.vue';

export default {
  components: {
    AddRequest,
    DetailedMetric,
    RequestSelector,
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
      keys: ['sql', 'cached', 'transaction', 'db_role'],
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
      metric: 'rugged',
      header: s__('PerformanceBar|Rugged calls'),
      keys: ['feature', 'args'],
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
    initialRequest() {
      return this.currentRequestId === this.requestId;
    },
    hasHost() {
      return this.currentRequest && this.currentRequest.details && this.currentRequest.details.host;
    },
    birdEmoji() {
      if (this.hasHost && this.currentRequest.details.host.canary) {
        return glEmojiTag('baby_chick');
      }
      return '';
    },
    downloadPath() {
      const data = JSON.stringify(this.requests);
      const blob = new Blob([data], { type: 'text/plain' });
      return window.URL.createObjectURL(blob);
    },
    downloadName() {
      const fileName = this.requests[0].truncatedUrl;
      return `${fileName}_perf_bar_${Date.now()}.json`;
    },
  },
  mounted() {
    this.currentRequest = this.requestId;
  },
  methods: {
    changeCurrentRequest(newRequestId) {
      this.currentRequest = newRequestId;
    },
  },
};
</script>
<template>
  <div id="js-peek" :class="env">
    <div
      v-if="currentRequest"
      class="d-flex container-fluid container-limited justify-content-center"
      data-qa-selector="performance_bar"
    >
      <div id="peek-view-host" class="view">
        <span
          v-if="hasHost"
          class="current-host"
          :class="{ canary: currentRequest.details.host.canary }"
        >
          <span v-html="birdEmoji"></span>
          {{ currentRequest.details.host.hostname }}
        </span>
      </div>
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
        <a class="gl-text-blue-200" :href="currentRequest.details.tracing.tracing_url">{{
          s__('PerformanceBar|Trace')
        }}</a>
      </div>
      <div v-if="currentRequest.details" id="peek-download" class="view">
        <a class="gl-text-blue-200" :download="downloadName" :href="downloadPath">{{
          s__('PerformanceBar|Download')
        }}</a>
      </div>
      <a v-if="statsUrl" class="gl-text-blue-200 view" :href="statsUrl">{{
        s__('PerformanceBar|Stats')
      }}</a>
      <request-selector
        v-if="currentRequest"
        :current-request="currentRequest"
        :requests="requests"
        class="ml-auto"
        @change-current-request="changeCurrentRequest"
      />
      <add-request v-on="$listeners" />
    </div>
  </div>
</template>
