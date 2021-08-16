<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlPopover } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { flatten } from 'lodash';
import createFlash from '~/flash';
import { sprintf, s__ } from '~/locale';
import { METRICS_POPOVER_CONTENT } from '../constants';
import { removeFlash, prepareTimeMetricsData } from '../utils';

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
    GlPopover,
    GlSingleStat,
    GlSkeletonLoading,
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
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-wrap" data-testid="vsa-time-metrics">
    <div v-if="isLoading" class="gl-h-auto gl-py-3 gl-pr-9 gl-my-6">
      <gl-skeleton-loading />
    </div>
    <template v-else>
      <div v-for="metric in metrics" :key="metric.key" class="gl-my-6 gl-pr-9">
        <gl-single-stat
          :id="metric.key"
          :value="`${metric.value}`"
          :title="metric.label"
          :unit="metric.unit || ''"
          :should-animate="true"
          :animation-decimal-places="1"
          tabindex="0"
        />
        <gl-popover :target="metric.key" placement="bottom">
          <template #title>
            <span class="gl-display-block gl-text-left">{{ metric.label }}</span>
          </template>
          <span v-if="metric.description">{{ metric.description }}</span>
        </gl-popover>
      </div>
    </template>
  </div>
</template>
