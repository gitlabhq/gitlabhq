<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { isEqual, keyBy } from 'lodash';
import { createAlert } from '~/alert';
import { sprintf, s__ } from '~/locale';
import { fetchMetricsData, removeFlash } from '../utils';
import ValueStreamsDashboardLink from './value_streams_dashboard_link.vue';
import MetricTile from './metric_tile.vue';

const extractMetricsGroupData = (keyList = [], data = []) => {
  if (!keyList.length || !data.length) return [];
  const kv = keyBy(data, 'identifier');
  return keyList.map((id) => kv[id] || null).filter((obj) => Boolean(obj));
};

const groupRawMetrics = (groups = [], rawData = []) => {
  return groups.map((curr) => {
    const { keys, ...rest } = curr;
    return {
      data: extractMetricsGroupData(keys, rawData),
      keys,
      ...rest,
    };
  });
};

export default {
  name: 'ValueStreamMetrics',
  components: {
    GlSkeletonLoader,
    MetricTile,
    ValueStreamsDashboardLink,
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
    groupBy: {
      type: Array,
      required: false,
      default: () => [],
    },
    dashboardsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      metrics: [],
      groupedMetrics: [],
      isLoading: false,
    };
  },
  computed: {
    hasGroupedMetrics() {
      return Boolean(this.groupBy.length);
    },
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
    shouldDisplayDashboardLink(index) {
      // When we have groups of metrics, we should only display the link for the first group
      return index === 0 && this.dashboardsPath;
    },
    fetchData() {
      removeFlash();
      this.isLoading = true;
      return fetchMetricsData(this.requests, this.requestPath, this.requestParams)
        .then((data) => {
          this.metrics = this.filterFn ? this.filterFn(data) : data;

          if (this.hasGroupedMetrics) {
            this.groupedMetrics = groupRawMetrics(this.groupBy, this.metrics);
          }

          this.isLoading = false;
        })
        .catch((err) => {
          const message = sprintf(
            s__(
              'ValueStreamAnalytics|There was an error while fetching value stream analytics %{requestTypeName} data.',
            ),
            { requestTypeName: err.message },
          );

          createAlert({ message });
          this.isLoading = false;
        });
    },
  },
};
</script>
<template>
  <div class="gl-display-flex" data-testid="vsa-metrics" :class="isLoading ? 'gl-my-6' : 'gl-mt-6'">
    <gl-skeleton-loader v-if="isLoading" />
    <template v-else>
      <div v-if="hasGroupedMetrics" class="gl-flex-direction-column">
        <div
          v-for="(group, groupIndex) in groupedMetrics"
          :key="group.key"
          class="gl-mb-7"
          data-testid="vsa-metrics-group"
        >
          <h4 class="gl-my-0">{{ group.title }}</h4>
          <div class="gl-display-flex gl-flex-wrap">
            <metric-tile
              v-for="metric in group.data"
              :key="metric.identifier"
              :metric="metric"
              class="gl-mt-5 gl-pr-10"
            />
            <value-streams-dashboard-link
              v-if="shouldDisplayDashboardLink(groupIndex)"
              class="gl-mt-5"
              :request-path="dashboardsPath"
            />
          </div>
        </div>
      </div>
      <div v-else class="gl-display-flex gl-flex-wrap gl-mb-7">
        <metric-tile
          v-for="metric in metrics"
          :key="metric.identifier"
          :metric="metric"
          class="gl-mt-5 gl-pr-10"
        />
      </div>
    </template>
  </div>
</template>
