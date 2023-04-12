<script>
import { GlLink, GlPopover } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { glEmojiTag } from '~/emoji';
import { mergeUrlParams } from '~/lib/utils/url_utility';

import { s__ } from '~/locale';
import AddRequest from './add_request.vue';
import DetailedMetric from './detailed_metric.vue';
import RequestSelector from './request_selector.vue';

export default {
  components: {
    GlPopover,
    AddRequest,
    DetailedMetric,
    GlLink,
    RequestSelector,
  },
  directives: {
    SafeHtml,
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
      metric: 'zkt',
      header: s__('PerformanceBar|Zoekt calls'),
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
    glEmojiTag,
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
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>
<template>
  <div id="js-peek" :class="env">
    <div
      v-if="currentRequest"
      class="d-flex container-fluid container-limited justify-content-center gl-align-items-center"
      data-qa-selector="performance_bar"
    >
      <div id="peek-view-host" class="view">
        <span
          v-if="hasHost"
          class="current-host"
          :class="{ canary: currentRequest.details.host.canary }"
        >
          <span id="canary-emoji" v-safe-html:[$options.safeHtmlConfig]="birdEmoji"></span>
          <gl-popover placement="bottom" target="canary-emoji" content="Canary" />
          <span
            id="host-emoji"
            v-safe-html:[$options.safeHtmlConfig]="glEmojiTag('computer')"
          ></span>
          <gl-popover
            placement="bottom"
            target="host-emoji"
            :content="currentRequest.details.host.hostname"
          />
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
        <gl-link class="gl-text-blue-200" :href="currentRequest.details.tracing.tracing_url">{{
          s__('PerformanceBar|Trace')
        }}</gl-link>
      </div>
      <div v-if="currentRequest.details" id="peek-download" class="view">
        <gl-link
          class="gl-text-blue-200"
          is-unsafe-link
          :download="downloadName"
          :href="downloadPath"
          >{{ s__('PerformanceBar|Download') }}</gl-link
        >
      </div>
      <div v-if="showMemoryReportButton" id="peek-memory-report" class="view">
        <gl-link class="gl-text-blue-200" :href="memoryReportPath">{{
          s__('PerformanceBar|Memory report')
        }}</gl-link>
      </div>
      <div v-if="showFlamegraphButtons" id="peek-flamegraph" class="view">
        <span id="flamegraph-emoji" class="gl-text-white-200">
          <span v-safe-html:[$options.safeHtmlConfig]="glEmojiTag('fire')"></span>
          <span v-safe-html:[$options.safeHtmlConfig]="glEmojiTag('bar_chart')"></span>
        </span>
        <gl-popover placement="bottom" target="flamegraph-emoji" content="Flamegraph" />
        <gl-link class="gl-text-blue-200" :href="flamegraphPath('wall', currentRequestId)">{{
          s__('PerformanceBar|wall')
        }}</gl-link>
        /
        <gl-link class="gl-text-blue-200" :href="flamegraphPath('cpu', currentRequestId)">{{
          s__('PerformanceBar|cpu')
        }}</gl-link>
        /
        <gl-link class="gl-text-blue-200" :href="flamegraphPath('object', currentRequestId)">{{
          s__('PerformanceBar|object')
        }}</gl-link>
      </div>
      <gl-link v-if="statsUrl" class="gl-text-blue-200 view" :href="statsUrl">{{
        s__('PerformanceBar|Stats')
      }}</gl-link>
      <request-selector
        v-if="currentRequest"
        :current-request="currentRequest"
        :requests="requests"
        class="gl-ml-auto"
        @change-current-request="changeCurrentRequest"
      />
      <add-request v-on="$listeners" />
    </div>
  </div>
</template>
