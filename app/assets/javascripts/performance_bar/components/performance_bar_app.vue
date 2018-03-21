<script>
import $ from 'jquery';

import PerformanceBarService from '../services/performance_bar_service';
import detailedMetric from './detailed_metric.vue';
import requestSelector from './request_selector.vue';
import simpleMetric from './simple_metric.vue';
import upstreamPerformanceBar from './upstream_performance_bar.vue';

import Flash from '../../flash';

export default {
  components: {
    detailedMetric,
    requestSelector,
    simpleMetric,
    upstreamPerformanceBar,
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
    { metric: 'pg', header: 'SQL queries', details: 'queries', keys: ['sql'] },
    {
      metric: 'gitaly',
      header: 'Gitaly calls',
      details: 'details',
      keys: ['feature', 'request'],
    },
  ],
  simpleMetrics: ['redis', 'sidekiq'],
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
  },
  mounted() {
    this.interceptor = PerformanceBarService.registerInterceptor(
      this.peekUrl,
      this.loadRequestDetails,
    );

    this.loadRequestDetails(this.requestId, window.location.href);
    this.currentRequest = this.requestId;

    if (this.lineProfileModal.length) {
      this.lineProfileModal.modal('toggle');
    }
  },
  beforeDestroy() {
    PerformanceBarService.removeInterceptor(this.interceptor);
  },
  methods: {
    loadRequestDetails(requestId, requestUrl) {
      if (!this.store.canTrackRequest(requestUrl)) {
        return;
      }

      this.store.addRequest(requestId, requestUrl);

      PerformanceBarService.fetchRequestDetails(this.peekUrl, requestId)
        .then(res => {
          this.store.addRequestDetails(requestId, res.data.data);
        })
        .catch(() =>
          Flash(`Error getting performance bar results for ${requestId}`),
        );
    },
    changeCurrentRequest(newRequestId) {
      this.currentRequest = newRequestId;
    },
  },
};
</script>
<template>
  <div
    id="js-peek"
    :class="env"
  >
    <request-selector
      v-if="currentRequest"
      :current-request="currentRequest"
      :requests="requests"
      @change-current-request="changeCurrentRequest"
    />
    <div
      id="peek-view-host"
      class="view prepend-left-5"
    >
      <span
        v-if="currentRequest && currentRequest.details"
        class="current-host"
      >
        {{ currentRequest.details.host.hostname }}
      </span>
    </div>
    <div
      v-if="currentRequest"
      class="wrapper"
    >
      <upstream-performance-bar
        v-if="initialRequest && currentRequest.details"
      />
      <detailed-metric
        v-for="metric in $options.detailedMetrics"
        :key="metric.metric"
        :current-request="currentRequest"
        :metric="metric.metric"
        :header="metric.header"
        :details="metric.details"
        :keys="metric.keys"
      />
      <div
        v-if="initialRequest"
        id="peek-view-rblineprof"
        class="view"
      >
        <button
          v-if="lineProfileModal.length"
          class="btn-link btn-blank"
          data-toggle="modal"
          data-target="#modal-peek-line-profile"
        >
          profile
        </button>
        <a
          v-else
          :href="profileUrl"
        >
          profile
        </a>
      </div>
      <simple-metric
        v-for="metric in $options.simpleMetrics"
        :current-request="currentRequest"
        :key="metric"
        :metric="metric"
      />
      <div
        id="peek-view-gc"
        class="view"
      >
        <span
          v-if="currentRequest.details"
          class="bold"
        >
          <span title="Invoke Time">{{ currentRequest.details.gc.gc_time }}</span>ms
          /
          <span title="Invoke Count">{{ currentRequest.details.gc.invokes }}</span>
          gc
        </span>
      </div>
    </div>
  </div>
</template>
