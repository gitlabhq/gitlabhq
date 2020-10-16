<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { GlAlert } from '@gitlab/ui';
import { mapKeys, mapValues, pick, some, sum } from 'lodash';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { s__ } from '~/locale';
import { formatDateAsMonth, getDayDifference } from '~/lib/utils/datetime_utility';
import { getAverageByMonth, sortByDate, extractValues } from '../utils';
import pipelineStatsQuery from '../graphql/queries/pipeline_stats.query.graphql';
import { TODAY, START_DATE } from '../constants';

const DATA_KEYS = [
  'pipelinesTotal',
  'pipelinesSucceeded',
  'pipelinesFailed',
  'pipelinesCanceled',
  'pipelinesSkipped',
];
const PREFIX = 'pipelines';

export default {
  name: 'PipelinesChart',
  components: {
    GlLineChart,
    GlAlert,
    ChartSkeletonLoader,
  },
  startDate: START_DATE,
  endDate: TODAY,
  i18n: {
    loadPipelineChartError: s__(
      'InstanceAnalytics|Could not load the pipelines chart. Please refresh the page to try again.',
    ),
    noDataMessage: s__('InstanceAnalytics|There is no data available.'),
    total: s__('InstanceAnalytics|Total'),
    succeeded: s__('InstanceAnalytics|Succeeded'),
    failed: s__('InstanceAnalytics|Failed'),
    canceled: s__('InstanceAnalytics|Canceled'),
    skipped: s__('InstanceAnalytics|Skipped'),
    chartTitle: s__('InstanceAnalytics|Pipelines'),
    yAxisTitle: s__('InstanceAnalytics|Items'),
    xAxisTitle: s__('InstanceAnalytics|Month'),
  },
  data() {
    return {
      loading: true,
      loadingError: null,
    };
  },
  apollo: {
    pipelineStats: {
      query: pipelineStatsQuery,
      variables() {
        return {
          firstTotal: this.totalDaysToShow,
          firstSucceeded: this.totalDaysToShow,
          firstFailed: this.totalDaysToShow,
          firstCanceled: this.totalDaysToShow,
          firstSkipped: this.totalDaysToShow,
        };
      },
      update(data) {
        const allData = extractValues(data, DATA_KEYS, PREFIX, 'nodes');
        const allPageInfo = extractValues(data, DATA_KEYS, PREFIX, 'pageInfo');

        return {
          ...mapValues(allData, sortByDate),
          ...allPageInfo,
        };
      },
      result() {
        if (this.hasNextPage) {
          this.fetchNextPage();
        }
      },
      error() {
        this.handleError();
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.pipelineStats.loading;
    },
    totalDaysToShow() {
      return getDayDifference(this.$options.startDate, this.$options.endDate);
    },
    firstVariables() {
      const allData = pick(this.pipelineStats, [
        'nodesTotal',
        'nodesSucceeded',
        'nodesFailed',
        'nodesCanceled',
        'nodesSkipped',
      ]);
      const allDayDiffs = mapValues(allData, data => {
        const firstdataPoint = data[0];
        if (!firstdataPoint) {
          return 0;
        }

        return Math.max(
          0,
          getDayDifference(this.$options.startDate, new Date(firstdataPoint.recordedAt)),
        );
      });

      return mapKeys(allDayDiffs, (value, key) => key.replace('nodes', 'first'));
    },
    cursorVariables() {
      const pageInfoKeys = [
        'pageInfoTotal',
        'pageInfoSucceeded',
        'pageInfoFailed',
        'pageInfoCanceled',
        'pageInfoSkipped',
      ];

      return extractValues(this.pipelineStats, pageInfoKeys, 'pageInfo', 'endCursor');
    },
    hasNextPage() {
      return (
        sum(Object.values(this.firstVariables)) > 0 &&
        some(this.pipelineStats, ({ hasNextPage }) => hasNextPage)
      );
    },
    hasEmptyDataSet() {
      return this.chartData.every(({ data }) => data.length === 0);
    },
    chartData() {
      const allData = pick(this.pipelineStats, [
        'nodesTotal',
        'nodesSucceeded',
        'nodesFailed',
        'nodesCanceled',
        'nodesSkipped',
      ]);
      const options = { shouldRound: true };
      return Object.keys(allData).map(key => {
        const i18nName = key.slice('nodes'.length).toLowerCase();
        return {
          name: this.$options.i18n[i18nName],
          data: getAverageByMonth(allData[key], options),
        };
      });
    },
    range() {
      return {
        min: this.$options.startDate,
        max: this.$options.endDate,
      };
    },
    differenceInMonths() {
      const yearDiff = this.$options.endDate.getYear() - this.$options.startDate.getYear();
      const monthDiff = this.$options.endDate.getMonth() - this.$options.startDate.getMonth();

      return monthDiff + 12 * yearDiff;
    },
    chartOptions() {
      return {
        xAxis: {
          ...this.range,
          name: this.$options.i18n.xAxisTitle,
          type: 'time',
          splitNumber: this.differenceInMonths + 1,
          axisLabel: {
            interval: 0,
            showMinLabel: false,
            showMaxLabel: false,
            align: 'right',
            formatter: formatDateAsMonth,
          },
        },
        yAxis: {
          name: this.$options.i18n.yAxisTitle,
        },
      };
    },
  },
  methods: {
    handleError() {
      this.loadingError = true;
    },
    fetchNextPage() {
      this.$apollo.queries.pipelineStats
        .fetchMore({
          variables: {
            ...this.firstVariables,
            ...this.cursorVariables,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return Object.keys(fetchMoreResult).reduce((memo, key) => {
              const { nodes, ...rest } = fetchMoreResult[key];
              const previousNodes = previousResult[key].nodes;
              return { ...memo, [key]: { ...rest, nodes: [...previousNodes, ...nodes] } };
            }, {});
          },
        })
        .catch(this.handleError);
    },
  },
};
</script>
<template>
  <div>
    <h3>{{ $options.i18n.chartTitle }}</h3>
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mt-3">
      {{ this.$options.i18n.loadPipelineChartError }}
    </gl-alert>
    <chart-skeleton-loader v-else-if="isLoading" />
    <gl-alert v-else-if="hasEmptyDataSet" variant="info" :dismissible="false" class="gl-mt-3">
      {{ $options.i18n.noDataMessage }}
    </gl-alert>
    <gl-line-chart v-else :option="chartOptions" :include-legend-avg-max="true" :data="chartData" />
  </div>
</template>
