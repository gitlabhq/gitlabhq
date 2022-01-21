<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { flatten } from 'lodash';
import createFlash from '~/flash';
import { sprintf, s__ } from '~/locale';
import { redirectTo } from '~/lib/utils/url_utility';
import { METRICS_POPOVER_CONTENT } from '../constants';
import { removeFlash, prepareTimeMetricsData } from '../utils';
import MetricPopover from './metric_popover.vue';

const requestData = ({ request, endpoint, path, params, name }) => {
  return request({ endpoint, params, requestPath: path })
    .then(({ data }) => data)
    .catch(() => {
      const message = sprintf(
        s__(
          'ValueStreamAnalytics|There was an error while fetching value stream analytics %{requestTypeName} data.',
        ),
        { requestTypeName: name },
      );
      createFlash({ message });
    });
};

const fetchMetricsData = (reqs = [], path, params) => {
  const promises = reqs.map((r) => requestData({ ...r, path, params }));
  return Promise.all(promises).then((responses) =>
    prepareTimeMetricsData(flatten(responses), METRICS_POPOVER_CONTENT),
  );
};

export default {
  name: 'ValueStreamMetrics',
  components: {
    GlSingleStat,
    GlSkeletonLoading,
    MetricPopover,
  },
  props: {
    requestPath: {
      type: String,
      required: true,
    },
    requestParams: {
      type: Object,
      required: true,
    },
    requests: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      metrics: [],
      isLoading: false,
    };
  },
  watch: {
    requestParams() {
      this.fetchData();
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      removeFlash();
      this.isLoading = true;
      return fetchMetricsData(this.requests, this.requestPath, this.requestParams)
        .then((data) => {
          this.metrics = data;
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
        });
    },
    hasLinks(links) {
      return links?.length && links[0].url;
    },
    clickHandler({ links }) {
      if (this.hasLinks(links)) {
        redirectTo(links[0].url);
      }
    },
    getDecimalPlaces(value) {
      const parsedFloat = parseFloat(value);
      return Number.isNaN(parsedFloat) || Number.isInteger(parsedFloat) ? 0 : 1;
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap" data-testid="vsa-time-metrics">
    <gl-skeleton-loading v-if="isLoading" class="gl-h-auto gl-py-3 gl-pr-9 gl-my-6" />
    <div
      v-for="metric in metrics"
      v-show="!isLoading"
      :key="metric.identifier"
      class="gl-my-6 gl-pr-9"
    >
      <gl-single-stat
        :id="metric.identifier"
        :value="`${metric.value}`"
        :title="metric.label"
        :unit="metric.unit || ''"
        :should-animate="true"
        :animation-decimal-places="getDecimalPlaces(metric.value)"
        :class="{ 'gl-hover-cursor-pointer': hasLinks(metric.links) }"
        tabindex="0"
        @click="clickHandler(metric)"
      />
      <metric-popover :metric="metric" :target="metric.identifier" />
    </div>
  </div>
</template>
