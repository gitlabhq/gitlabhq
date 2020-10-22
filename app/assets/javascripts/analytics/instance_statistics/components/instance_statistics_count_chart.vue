<script>
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { GlAlert } from '@gitlab/ui';
import { mapValues, some, sum } from 'lodash';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  differenceInMonths,
  formatDateAsMonth,
  getDayDifference,
} from '~/lib/utils/datetime_utility';
import { convertToTitleCase } from '~/lib/utils/text_utility';
import { getAverageByMonth, sortByDate, extractValues } from '../utils';
import { TODAY, START_DATE } from '../constants';

export default {
  name: 'InstanceStatisticsCountChart',
  components: {
    GlLineChart,
    GlAlert,
    ChartSkeletonLoader,
  },
  startDate: START_DATE,
  endDate: TODAY,
  dataKey: 'nodes',
  pageInfoKey: 'pageInfo',
  firstKey: 'first',
  props: {
    prefix: {
      type: String,
      required: true,
    },
    keyToNameMap: {
      type: Object,
      required: true,
    },
    chartTitle: {
      type: String,
      required: true,
    },
    loadChartErrorMessage: {
      type: String,
      required: true,
    },
    noDataMessage: {
      type: String,
      required: true,
    },
    xAxisTitle: {
      type: String,
      required: true,
    },
    yAxisTitle: {
      type: String,
      required: true,
    },
    query: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      loadingError: null,
    };
  },
  apollo: {
    pipelineStats: {
      query() {
        return this.query;
      },
      variables() {
        return this.nameKeys.reduce((memo, key) => {
          const firstKey = `${this.$options.firstKey}${convertToTitleCase(key)}`;
          return { ...memo, [firstKey]: this.totalDaysToShow };
        }, {});
      },
      update(data) {
        const allData = extractValues(data, this.nameKeys, this.prefix, this.$options.dataKey);
        const allPageInfo = extractValues(
          data,
          this.nameKeys,
          this.prefix,
          this.$options.pageInfoKey,
        );

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
    nameKeys() {
      return Object.keys(this.keyToNameMap);
    },
    isLoading() {
      return this.$apollo.queries.pipelineStats.loading;
    },
    totalDaysToShow() {
      return getDayDifference(this.$options.startDate, this.$options.endDate);
    },
    firstVariables() {
      const firstDataPoints = extractValues(
        this.pipelineStats,
        this.nameKeys,
        this.$options.dataKey,
        '[0].recordedAt',
        { renameKey: this.$options.firstKey },
      );

      return Object.keys(firstDataPoints).reduce((memo, name) => {
        const recordedAt = firstDataPoints[name];
        if (!recordedAt) {
          return { ...memo, [name]: 0 };
        }

        const numberOfDays = Math.max(
          0,
          getDayDifference(this.$options.startDate, new Date(recordedAt)),
        );

        return { ...memo, [name]: numberOfDays };
      }, {});
    },
    cursorVariables() {
      return extractValues(
        this.pipelineStats,
        this.nameKeys,
        this.$options.pageInfoKey,
        'endCursor',
      );
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
      const options = { shouldRound: true };

      return this.nameKeys.map(key => {
        const dataKey = `${this.$options.dataKey}${convertToTitleCase(key)}`;
        return {
          name: this.keyToNameMap[key],
          data: getAverageByMonth(this.pipelineStats?.[dataKey], options),
        };
      });
    },
    range() {
      return {
        min: this.$options.startDate,
        max: this.$options.endDate,
      };
    },
    chartOptions() {
      const { endDate, startDate } = this.$options;
      return {
        xAxis: {
          ...this.range,
          name: this.xAxisTitle,
          type: 'time',
          splitNumber: differenceInMonths(startDate, endDate) + 1,
          axisLabel: {
            interval: 0,
            showMinLabel: false,
            showMaxLabel: false,
            align: 'right',
            formatter: formatDateAsMonth,
          },
        },
        yAxis: {
          name: this.yAxisTitle,
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
    <h3>{{ chartTitle }}</h3>
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mt-3">
      {{ loadChartErrorMessage }}
    </gl-alert>
    <chart-skeleton-loader v-else-if="isLoading" />
    <gl-alert v-else-if="hasEmptyDataSet" variant="info" :dismissible="false" class="gl-mt-3">
      {{ noDataMessage }}
    </gl-alert>
    <gl-line-chart v-else :option="chartOptions" :include-legend-avg-max="true" :data="chartData" />
  </div>
</template>
