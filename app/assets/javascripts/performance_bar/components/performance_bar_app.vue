<script>
import { glEmojiTag } from '~/emoji';

import detailedMetric from './detailed_metric.vue';
import requestSelector from './request_selector.vue';
import { s__ } from '~/locale';

export default {
  components: {
    detailedMetric,
    requestSelector,
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
  },
  detailedMetrics: [
    {
      metric: 'active-record',
      title: 'pg',
      header: s__('PerformanceBar|SQL queries'),
      keys: ['sql'],
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
      keys: ['cmd'],
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
    <div v-if="currentRequest" class="d-flex container-fluid container-limited qa-performance-bar">
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
        <a :href="currentRequest.details.tracing.tracing_url">{{ s__('PerformanceBar|trace') }}</a>
      </div>
      <request-selector
        v-if="currentRequest"
        :current-request="currentRequest"
        :requests="requests"
        class="ml-auto"
        @change-current-request="changeCurrentRequest"
      />
    </div>
  </div>
</template>
