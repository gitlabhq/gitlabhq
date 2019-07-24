<script>
import $ from 'jquery';
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
    profileUrl: {
      type: String,
      required: true,
    },
  },
  detailedMetrics: [
    { metric: 'pg', header: s__('PerformanceBar|SQL queries'), details: 'queries', keys: ['sql'] },
    {
      metric: 'gitaly',
      header: s__('PerformanceBar|Gitaly calls'),
      details: 'details',
      keys: ['feature', 'request'],
    },
    {
      metric: 'rugged',
      header: 'Rugged calls',
      details: 'details',
      keys: ['feature', 'args'],
    },
    {
      metric: 'redis',
      header: 'Redis calls',
      details: 'details',
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
    lineProfileModal() {
      return $('#modal-peek-line-profile');
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

    if (this.lineProfileModal.length) {
      this.lineProfileModal.modal('toggle');
    }
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
        :header="metric.header"
        :details="metric.details"
        :keys="metric.keys"
      />
      <div v-if="initialRequest" id="peek-view-rblineprof" class="view">
        <button
          v-if="lineProfileModal.length"
          class="btn-link btn-blank"
          data-toggle="modal"
          data-target="#modal-peek-line-profile"
        >
          {{ s__('PerformanceBar|profile') }}
        </button>
        <a v-else :href="profileUrl">{{ s__('PerformanceBar|profile') }}</a>
      </div>
      <div id="peek-view-gc" class="view">
        <span v-if="currentRequest.details" class="bold">
          <span title="Invoke Time">{{ currentRequest.details.gc.gc_time }}</span
          >ms / <span title="Invoke Count">{{ currentRequest.details.gc.invokes }}</span> gc
        </span>
      </div>
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
