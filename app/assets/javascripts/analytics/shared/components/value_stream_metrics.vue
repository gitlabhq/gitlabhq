<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import {
  DORA_METRICS_QUERY_TYPE,
  FLOW_METRICS_QUERY_TYPE,
  ALL_METRICS_QUERY_TYPE,
  VALUE_STREAM_METRIC_TILE_METADATA,
} from '../constants';
import { rawMetricToMetricTile, extractQueryResponseFromNamespace, toYmd } from '../utils';
import { BUCKETING_INTERVAL_ALL, FLOW_METRICS_QUERY_FILTERS } from '../graphql/constants';
import FlowMetricsQuery from '../graphql/flow_metrics.query.graphql';
import FOSSFlowMetricsQuery from '../graphql/foss.flow_metrics.query.graphql';
import DoraMetricsQuery from '../graphql/dora_metrics.query.graphql';
import FlowMetricsCommitsQuery from '../graphql/commits.flow_metrics.query.graphql';
import ValueStreamsDashboardLink from './value_streams_dashboard_link.vue';
import MetricTile from './metric_tile.vue';

const extractMetricsGroupData = (keyList = [], data = []) => {
  return keyList.reduce((acc, curr) => {
    const metric = data.find((item) => item.identifier === curr);
    return metric ? [...acc, metric] : acc;
  }, []);
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
    queryType: {
      type: String,
      required: false,
      default: ALL_METRICS_QUERY_TYPE,
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
    isProjectNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLicensed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      flowMetricsCommits: {},
      flowMetrics: [],
      doraMetrics: [],
    };
  },
  computed: {
    queryDateRange() {
      const { startDate, endDate } = this.requestParams;
      return { startDate: toYmd(startDate), endDate: toYmd(endDate) };
    },
    flowMetricsVariables() {
      const additionalParams = FLOW_METRICS_QUERY_FILTERS.reduce((acc, key) => {
        if (this.requestParams[key]) {
          return { ...acc, [key]: this.requestParams[key] };
        }
        return acc;
      }, {});
      return { fullPath: this.requestPath, ...this.queryDateRange, ...additionalParams };
    },
    hasGroupedMetrics() {
      return Boolean(this.groupBy.length);
    },
    isLoading() {
      return Boolean(
        this.$apollo.queries.doraMetrics.loading ||
          this.$apollo.queries.flowMetrics.loading ||
          this.$apollo.queries.flowMetricsCommits.loading,
      );
    },
    groupedMetrics() {
      return groupRawMetrics(this.groupBy, this.metrics);
    },
    isFlowMetricsQuery() {
      return [ALL_METRICS_QUERY_TYPE, FLOW_METRICS_QUERY_TYPE].includes(this.queryType);
    },
    isDoraMetricsQuery() {
      return [ALL_METRICS_QUERY_TYPE, DORA_METRICS_QUERY_TYPE].includes(this.queryType);
    },
    displayableMetrics() {
      // NOTE: workaround while the flowMetrics/doraMetrics dont support including/excluding unwanted metrics from the response
      // it would be useful to return this to the frontend with relevant permissions checks having occurred on the backend
      return Object.keys(VALUE_STREAM_METRIC_TILE_METADATA);
    },
    flowMetricsCommitsResponse() {
      return this.flowMetricsCommits?.identifier ? [this.flowMetricsCommits] : [];
    },
    metrics() {
      const combined = [
        ...this.flowMetrics,
        ...this.doraMetrics,
        ...this.flowMetricsCommitsResponse,
      ].filter(({ identifier }) => this.displayableMetrics.includes(identifier));
      const filtered = this.filterFn ? this.filterFn(combined) : combined;
      return filtered.map((metric) => rawMetricToMetricTile(metric));
    },
  },
  watch: {
    async requestParams(newVal, oldVal) {
      if (!isEqual(newVal, oldVal)) {
        await Promise.all([
          this.$apollo.queries.doraMetrics.refetch(),
          this.$apollo.queries.flowMetrics.refetch(),
          this.$apollo.queries.flowMetricsCommits.refetch(),
        ]);
      }
    },
  },
  apollo: {
    flowMetricsCommits: {
      query: FlowMetricsCommitsQuery,
      variables() {
        return this.flowMetricsVariables;
      },
      skip() {
        return !this.isFlowMetricsQuery || !this.isProjectNamespace;
      },
      update(data) {
        return data?.flowMetricsCommits ? data.flowMetricsCommits : {};
      },
    },
    flowMetrics: {
      query() {
        // NOTE: we don't have a way to include/exclude fields from the query, the queries
        //      subsequently fail if we query fields that arent available / applicable
        //      Related issue created: https://gitlab.com/gitlab-org/gitlab/-/issues/506282
        return this.isLicensed ? FlowMetricsQuery : FOSSFlowMetricsQuery;
      },
      variables() {
        return this.flowMetricsVariables;
      },
      skip() {
        return !this.isFlowMetricsQuery;
      },
      update(data) {
        const metrics = extractQueryResponseFromNamespace({
          result: { data },
          resultKey: 'flowMetrics',
        });

        return Object.values(metrics).filter((metric) => metric?.identifier);
      },
      error() {
        createAlert({
          message: s__('ValueStreamAnalytics|There was an error while fetching flow metrics data.'),
        });
      },
    },
    doraMetrics: {
      query: DoraMetricsQuery,
      variables() {
        return {
          ...this.queryDateRange,
          fullPath: this.requestPath,
          interval: BUCKETING_INTERVAL_ALL,
        };
      },
      skip() {
        return !this.isLicensed || !this.isDoraMetricsQuery;
      },
      update(data) {
        const responseData = extractQueryResponseFromNamespace({
          result: { data },
          resultKey: 'dora',
        });

        const [rawMetrics] = responseData.metrics;
        return Object.entries(rawMetrics).reduce((acc, [identifier, value]) => {
          return [...acc, { identifier, value }];
        }, []);
      },
      error() {
        createAlert({
          message: s__('ValueStreamAnalytics|There was an error while fetching DORA metrics data.'),
        });
      },
    },
  },
  methods: {
    shouldDisplayDashboardLink(index) {
      // When we have groups of metrics, we should only display the link for the first group
      return index === 0 && this.dashboardsPath;
    },
  },
};
</script>
<template>
  <div class="gl-flex" data-testid="vsa-metrics" :class="isLoading ? 'gl-my-6' : 'gl-mt-6'">
    <gl-skeleton-loader v-if="isLoading" />
    <template v-else>
      <div v-if="hasGroupedMetrics" class="gl-flex-col">
        <div
          v-for="(group, groupIndex) in groupedMetrics"
          :key="group.key"
          class="gl-mb-7"
          data-testid="vsa-metrics-group"
        >
          <h4 class="gl-my-0">{{ group.title }}</h4>
          <div class="gl-flex gl-flex-wrap">
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
      <div v-else class="gl-mb-7 gl-flex gl-flex-wrap">
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
