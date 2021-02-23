<script>
import { GlAlert } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import * as Sentry from '@sentry/browser';
import { some, every } from 'lodash';
import {
  differenceInMonths,
  formatDateAsMonth,
  getDayDifference,
} from '~/lib/utils/datetime_utility';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { TODAY, START_DATE } from '../constants';
import { getAverageByMonth, getEarliestDate, generateDataKeys } from '../utils';

const QUERY_DATA_KEY = 'usageTrendsMeasurements';

export default {
  name: 'UsageTrendsCountChart',
  components: {
    GlLineChart,
    GlAlert,
    ChartSkeletonLoader,
  },
  startDate: START_DATE,
  endDate: TODAY,
  props: {
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
    queries: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      errors: { ...generateDataKeys(this.queries, '') },
      ...generateDataKeys(this.queries, []),
    };
  },
  computed: {
    errorMessages() {
      return Object.values(this.errors);
    },
    isLoading() {
      return some(this.$apollo.queries, (query) => query?.loading);
    },
    allQueriesFailed() {
      return every(this.errorMessages, (message) => message.length);
    },
    hasLoadingErrors() {
      return some(this.errorMessages, (message) => message.length);
    },
    errorMessage() {
      // show the generic loading message if all requests fail
      return this.allQueriesFailed ? this.loadChartErrorMessage : this.errorMessages.join('\n\n');
    },
    hasEmptyDataSet() {
      return this.chartData.every(({ data }) => data.length === 0);
    },
    totalDaysToShow() {
      return getDayDifference(this.$options.startDate, this.$options.endDate);
    },
    chartData() {
      const options = { shouldRound: true };
      return this.queries.map(({ identifier, title }) => ({
        name: title,
        data: getAverageByMonth(this[identifier]?.nodes, options),
      }));
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
  created() {
    this.queries.forEach(({ query, identifier, loadError }) => {
      this.$apollo.addSmartQuery(identifier, {
        query,
        variables() {
          return {
            identifier,
            first: this.totalDaysToShow,
            after: null,
          };
        },
        update(data) {
          const { nodes = [], pageInfo } = data[QUERY_DATA_KEY] || {};
          return {
            nodes,
            pageInfo,
          };
        },
        result() {
          const { pageInfo, nodes } = this[identifier];
          if (pageInfo?.hasNextPage && this.calculateDaysToFetch(getEarliestDate(nodes)) > 0) {
            this.fetchNextPage({
              query: this.$apollo.queries[identifier],
              errorMessage: loadError,
              pageInfo,
              identifier,
            });
          }
        },
        error(error) {
          this.handleError({
            message: loadError,
            identifier,
            error,
          });
        },
      });
    });
  },
  methods: {
    calculateDaysToFetch(firstDataPointDate = null) {
      return firstDataPointDate
        ? Math.max(0, getDayDifference(this.$options.startDate, new Date(firstDataPointDate)))
        : 0;
    },
    handleError({ identifier, error, message }) {
      this.loadingError = true;
      this.errors = { ...this.errors, [identifier]: message };
      Sentry.captureException(error);
    },
    fetchNextPage({ query, pageInfo, identifier, errorMessage }) {
      query
        .fetchMore({
          variables: {
            identifier,
            first: this.calculateDaysToFetch(getEarliestDate(this[identifier].nodes)),
            after: pageInfo.endCursor,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            const { nodes, ...rest } = fetchMoreResult[QUERY_DATA_KEY];
            const { nodes: previousNodes } = previousResult[QUERY_DATA_KEY];
            return {
              [QUERY_DATA_KEY]: { ...rest, nodes: [...previousNodes, ...nodes] },
            };
          },
        })
        .catch((error) => this.handleError({ identifier, error, message: errorMessage }));
    },
  },
};
</script>
<template>
  <div>
    <h3>{{ chartTitle }}</h3>
    <gl-alert v-if="hasLoadingErrors" variant="danger" :dismissible="false" class="gl-mt-3">
      {{ errorMessage }}
    </gl-alert>
    <div v-if="!allQueriesFailed">
      <chart-skeleton-loader v-if="isLoading" />
      <gl-alert v-else-if="hasEmptyDataSet" variant="info" :dismissible="false" class="gl-mt-3">
        {{ noDataMessage }}
      </gl-alert>
      <gl-line-chart
        v-else
        :option="chartOptions"
        :include-legend-avg-max="true"
        :data="chartData"
      />
    </div>
  </div>
</template>
