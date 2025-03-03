<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import {
  DATE_RANGE_LAST_WEEK,
  DATE_RANGE_LAST_30_DAYS,
  DATE_RANGE_LAST_90_DAYS,
  DATE_RANGE_LAST_180_DAYS,
} from '../constants';
import getPipelineAnalytics from '../graphql/queries/get_pipeline_analytics.query.graphql';
import StatisticsList from './statistics_list.vue';
import PipelineDurationChart from './pipeline_duration_chart.vue';
import PipelineStatusChart from './pipeline_status_chart.vue';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    StatisticsList,
    PipelineDurationChart,
    PipelineStatusChart,
  },
  inject: {
    projectPath: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      dateRange: DATE_RANGE_LAST_WEEK,
      pipelineAnalytics: {
        aggregate: {
          count: null,
          successCount: null,
          failedCount: null,
          durationStatistics: {
            p50: null,
          },
        },
        timeSeries: [],
      },
    };
  },
  apollo: {
    pipelineAnalytics: {
      query: getPipelineAnalytics,
      variables() {
        return {
          fullPath: this.projectPath,
          fromTime: getDateInPast(new Date(), this.dateRange),
          toTime: new Date(),
        };
      },
      update(data) {
        return data?.project?.pipelineAnalytics;
      },
      error() {
        createAlert({
          message: s__(
            'PipelineCharts|An error occurred while loading pipeline analytics. Please try refreshing the page.',
          ),
        });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.pipelineAnalytics.loading;
    },
    formattedCounts() {
      const { count, successCount, failedCount, durationStatistics } =
        this.pipelineAnalytics.aggregate;
      return {
        total: count === null ? '-' : count,
        meanDuration: durationStatistics.p50,
        successRatio: Number(count) ? (successCount / count) * 100 : 0,
        failureRatio: Number(count) ? (failedCount / count) * 100 : 0,
      };
    },
  },
  dateRangeItems: [
    {
      text: s__('PipelineCharts|Last week'),
      value: DATE_RANGE_LAST_WEEK,
    },
    {
      text: s__('PipelineCharts|Last 30 days'),
      value: DATE_RANGE_LAST_30_DAYS,
    },
    {
      text: s__('PipelineCharts|Last 90 days'),
      value: DATE_RANGE_LAST_90_DAYS,
    },
    {
      text: s__('PipelineCharts|Last 180 days'),
      value: DATE_RANGE_LAST_180_DAYS,
    },
  ],
};
</script>
<template>
  <div>
    <h2>{{ s__('PipelineCharts|Pipelines') }}</h2>
    <div class="gl-mb-4 gl-bg-subtle gl-p-4 gl-pb-2">
      <gl-form-group :label="__('Date range')" label-for="date-range">
        <gl-collapsible-listbox
          id="date-range"
          v-model="dateRange"
          :items="$options.dateRangeItems"
        />
      </gl-form-group>
    </div>
    <div>
      <statistics-list :loading="loading" :counts="formattedCounts" />
      <pipeline-duration-chart :loading="loading" :time-series="pipelineAnalytics.timeSeries" />
      <pipeline-status-chart :loading="loading" :time-series="pipelineAnalytics.timeSeries" />
    </div>
  </div>
</template>
