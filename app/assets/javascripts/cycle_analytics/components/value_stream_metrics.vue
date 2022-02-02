<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { flatten, isEqual } from 'lodash';
import createFlash from '~/flash';
import { sprintf, s__ } from '~/locale';
import { METRICS_POPOVER_CONTENT } from '../constants';
import { removeFlash, prepareTimeMetricsData } from '../utils';
import MetricTile from './metric_tile.vue';

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
    GlSkeletonLoading,
    MetricTile,
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
    filterFn: {
      type: Function,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      metrics: [],
      isLoading: false,
    };
  },
  watch: {
    requestParams(newVal, oldVal) {
      if (!isEqual(newVal, oldVal)) {
        this.fetchData();
      }
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
          this.metrics = this.filterFn ? this.filterFn(data) : data;
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap" data-testid="vsa-metrics">
    <gl-skeleton-loading v-if="isLoading" class="gl-h-auto gl-py-3 gl-pr-9 gl-my-6" />
    <metric-tile
      v-for="metric in metrics"
      v-show="!isLoading"
      :key="metric.identifier"
      :metric="metric"
      class="gl-my-6 gl-pr-9"
    />
  </div>
</template>
