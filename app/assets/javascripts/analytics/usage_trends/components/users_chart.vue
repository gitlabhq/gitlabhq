<script>
import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import * as Sentry from '@sentry/browser';
import produce from 'immer';
import { sortBy } from 'lodash';
import { formatDateAsMonth } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import usersQuery from '../graphql/queries/users.query.graphql';
import { getAverageByMonth } from '../utils';

const sortByDate = (data) => sortBy(data, (item) => new Date(item[0]).getTime());

export default {
  name: 'UsersChart',
  components: { GlAlert, GlAreaChart, ChartSkeletonLoader },
  props: {
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    totalDataPoints: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loadingError: null,
      users: [],
      pageInfo: null,
    };
  },
  apollo: {
    users: {
      query: usersQuery,
      variables() {
        return {
          first: this.totalDataPoints,
          after: null,
        };
      },
      update(data) {
        return data.users?.nodes || [];
      },
      result({ data }) {
        const {
          users: { pageInfo },
        } = data;
        this.pageInfo = pageInfo;
        this.fetchNextPage();
      },
      error(error) {
        this.handleError(error);
      },
    },
  },
  i18n: {
    yAxisTitle: __('Total users'),
    xAxisTitle: __('Month'),
    loadUserChartError: __('Could not load the user chart. Please refresh the page to try again.'),
    noDataMessage: __('There is no data available.'),
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.users.loading || this.pageInfo?.hasNextPage;
    },
    chartUserData() {
      const averaged = getAverageByMonth(
        this.users.length > this.totalDataPoints
          ? this.users.slice(0, this.totalDataPoints)
          : this.users,
        { shouldRound: true },
      );
      return sortByDate(averaged);
    },
    options() {
      return {
        xAxis: {
          name: this.$options.i18n.xAxisTitle,
          type: 'category',
          axisLabel: {
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
    handleError(error) {
      this.loadingError = true;
      this.users = [];
      Sentry.captureException(error);
    },
    fetchNextPage() {
      if (this.pageInfo?.hasNextPage) {
        this.$apollo.queries.users
          .fetchMore({
            variables: { first: this.totalDataPoints, after: this.pageInfo.endCursor },
            updateQuery: (previousResult, { fetchMoreResult }) => {
              return produce(fetchMoreResult, (newUsers) => {
                // eslint-disable-next-line no-param-reassign
                newUsers.users.nodes = [...previousResult.users.nodes, ...newUsers.users.nodes];
              });
            },
          })
          .catch(this.handleError);
      }
    },
  },
};
</script>
<template>
  <div>
    <h3>{{ $options.i18n.yAxisTitle }}</h3>
    <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mt-3">
      {{ this.$options.i18n.loadUserChartError }}
    </gl-alert>
    <chart-skeleton-loader v-else-if="isLoading" />
    <gl-alert v-else-if="!chartUserData.length" variant="info" :dismissible="false" class="gl-mt-3">
      {{ $options.i18n.noDataMessage }}
    </gl-alert>
    <gl-area-chart
      v-else
      :option="options"
      :include-legend-avg-max="true"
      :data="[
        {
          name: $options.i18n.yAxisTitle,
          data: chartUserData,
        },
      ]"
    />
  </div>
</template>
