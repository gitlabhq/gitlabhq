<script>
import { GlAlert } from '@gitlab/ui';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import produce from 'immer';
import { sortBy } from 'lodash';
import * as Sentry from '~/sentry/wrapper';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import { s__, __ } from '~/locale';
import { formatDateAsMonth } from '~/lib/utils/datetime_utility';
import latestGroupsQuery from '../graphql/queries/groups.query.graphql';
import latestProjectsQuery from '../graphql/queries/projects.query.graphql';
import { getAverageByMonth } from '../utils';

const sortByDate = data => sortBy(data, item => new Date(item[0]).getTime());

const averageAndSortData = (data = [], maxDataPoints) => {
  const averaged = getAverageByMonth(
    data.length > maxDataPoints ? data.slice(0, maxDataPoints) : data,
    { shouldRound: true },
  );
  return sortByDate(averaged);
};

export default {
  name: 'ProjectsAndGroupsChart',
  components: { GlAlert, GlLineChart, ChartSkeletonLoader },
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
      loadingError: false,
      errorMessage: '',
      groups: [],
      projects: [],
      groupsPageInfo: null,
      projectsPageInfo: null,
    };
  },
  apollo: {
    groups: {
      query: latestGroupsQuery,
      variables() {
        return {
          first: this.totalDataPoints,
          after: null,
        };
      },
      update(data) {
        return data.groups?.nodes || [];
      },
      result({ data }) {
        const {
          groups: { pageInfo },
        } = data;
        this.groupsPageInfo = pageInfo;
        this.fetchNextPage({
          query: this.$apollo.queries.groups,
          pageInfo: this.groupsPageInfo,
          dataKey: 'groups',
          errorMessage: this.$options.i18n.loadGroupsDataError,
        });
      },
      error(error) {
        this.handleError({
          message: this.$options.i18n.loadGroupsDataError,
          error,
          dataKey: 'groups',
        });
      },
    },
    projects: {
      query: latestProjectsQuery,
      variables() {
        return {
          first: this.totalDataPoints,
          after: null,
        };
      },
      update(data) {
        return data.projects?.nodes || [];
      },
      result({ data }) {
        const {
          projects: { pageInfo },
        } = data;
        this.projectsPageInfo = pageInfo;
        this.fetchNextPage({
          query: this.$apollo.queries.projects,
          pageInfo: this.projectsPageInfo,
          dataKey: 'projects',
          errorMessage: this.$options.i18n.loadProjectsDataError,
        });
      },
      error(error) {
        this.handleError({
          message: this.$options.i18n.loadProjectsDataError,
          error,
          dataKey: 'projects',
        });
      },
    },
  },
  i18n: {
    yAxisTitle: s__('InstanceStatistics|Total projects & groups'),
    xAxisTitle: __('Month'),
    loadChartError: s__(
      'InstanceStatistics|Could not load the projects and groups chart. Please refresh the page to try again.',
    ),
    loadProjectsDataError: s__('InstanceStatistics|There was an error while loading the projects'),
    loadGroupsDataError: s__('InstanceStatistics|There was an error while loading the groups'),
    noDataMessage: s__('InstanceStatistics|No data available.'),
  },
  computed: {
    isLoadingGroups() {
      return this.$apollo.queries.groups.loading || this.groupsPageInfo?.hasNextPage;
    },
    isLoadingProjects() {
      return this.$apollo.queries.projects.loading || this.projectsPageInfo?.hasNextPage;
    },
    isLoading() {
      return this.isLoadingProjects && this.isLoadingGroups;
    },
    groupChartData() {
      return averageAndSortData(this.groups, this.totalDataPoints);
    },
    projectChartData() {
      return averageAndSortData(this.projects, this.totalDataPoints);
    },
    hasNoData() {
      const { projectChartData, groupChartData } = this;
      return Boolean(!projectChartData.length && !groupChartData.length);
    },
    options() {
      return {
        xAxis: {
          name: this.$options.i18n.xAxisTitle,
          type: 'category',
          axisLabel: {
            formatter: value => {
              return formatDateAsMonth(value);
            },
          },
        },
        yAxis: {
          name: this.$options.i18n.yAxisTitle,
        },
      };
    },
    chartData() {
      return [
        {
          name: s__('InstanceStatistics|Total projects'),
          data: this.projectChartData,
        },
        {
          name: s__('InstanceStatistics|Total groups'),
          data: this.groupChartData,
        },
      ];
    },
  },
  methods: {
    handleError({ error, message = this.$options.i18n.loadChartError, dataKey = null }) {
      this.loadingError = true;
      this.errorMessage = message;
      if (!dataKey) {
        this.projects = [];
        this.groups = [];
      } else {
        this[dataKey] = [];
      }
      Sentry.captureException(error);
    },
    fetchNextPage({ pageInfo, query, dataKey, errorMessage }) {
      if (pageInfo?.hasNextPage) {
        query
          .fetchMore({
            variables: { first: this.totalDataPoints, after: pageInfo.endCursor },
            updateQuery: (previousResult, { fetchMoreResult }) => {
              const results = produce(fetchMoreResult, newData => {
                // eslint-disable-next-line no-param-reassign
                newData[dataKey].nodes = [
                  ...previousResult[dataKey].nodes,
                  ...newData[dataKey].nodes,
                ];
              });
              return results;
            },
          })
          .catch(error => {
            this.handleError({ error, message: errorMessage, dataKey });
          });
      }
    },
  },
};
</script>
<template>
  <div>
    <h3>{{ $options.i18n.yAxisTitle }}</h3>
    <chart-skeleton-loader v-if="isLoading" />
    <gl-alert v-else-if="hasNoData" variant="info" :dismissible="false" class="gl-mt-3">
      {{ $options.i18n.noDataMessage }}
    </gl-alert>
    <div v-else>
      <gl-alert v-if="loadingError" variant="danger" :dismissible="false" class="gl-mt-3">{{
        errorMessage
      }}</gl-alert>
      <gl-line-chart :option="options" :include-legend-avg-max="true" :data="chartData" />
    </div>
  </div>
</template>
