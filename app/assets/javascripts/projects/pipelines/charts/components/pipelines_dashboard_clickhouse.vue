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
import DashboardHeader from './dashboard_header.vue';
import StatisticsList from './statistics_list.vue';
import PipelineDurationChart from './pipeline_duration_chart.vue';
import PipelineStatusChart from './pipeline_status_chart.vue';

// CiPipelineCiSources values from GraphQL schema.
const SOURCE_ANY = 'ANY';
const SOURCE_PUSH = 'PUSH';
const SOURCE_WEB = 'WEB';
const SOURCE_TRIGGER = 'TRIGGER';
const SOURCE_SCHEDULE = 'SCHEDULE';
const SOURCE_API = 'API';
const SOURCE_EXTERNAL = 'EXTERNAL';
const SOURCE_PIPELINE = 'PIPELINE';
const SOURCE_CHAT = 'CHAT';
const SOURCE_MERGE_REQUEST_EVENT = 'MERGE_REQUEST_EVENT';
const SOURCE_EXTERNAL_PULL_REQUEST_EVENT = 'EXTERNAL_PULL_REQUEST_EVENT';
const SOURCE_UNKNOWN = 'UNKNOWN';

export default {
  name: 'PipelinesDashboardClickhouse',
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    DashboardHeader,
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
      source: SOURCE_ANY,
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
        return this.variables;
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
    variables() {
      // Use UTC time and take beginning of day
      const today = new Date(new Date().setUTCHours(0, 0, 0, 0));

      return {
        fullPath: this.projectPath,
        source: this.source === SOURCE_ANY ? null : this.source,
        fromTime: getDateInPast(today, this.dateRange),
        toTime: today,
      };
    },
    formattedCounts() {
      const { count, successCount, failedCount, durationStatistics } =
        this.pipelineAnalytics.aggregate;
      return {
        total: count === null ? '-' : count,
        medianDuration: durationStatistics.p50,
        successRatio: Number(count) ? (successCount / count) * 100 : 0,
        failureRatio: Number(count) ? (failedCount / count) * 100 : 0,
      };
    },
  },
  pipelineSources: [
    { value: SOURCE_ANY, text: s__('PipelineSource|Any') },
    { value: SOURCE_PUSH, text: s__('PipelineSource|Push') },
    { value: SOURCE_WEB, text: s__('PipelineSource|Web') },
    { value: SOURCE_TRIGGER, text: s__('PipelineSource|Trigger') },
    { value: SOURCE_SCHEDULE, text: s__('PipelineSource|Schedule') },
    { value: SOURCE_API, text: s__('PipelineSource|API') },
    { value: SOURCE_EXTERNAL, text: s__('PipelineSource|External event') },
    { value: SOURCE_PIPELINE, text: s__('PipelineSource|Pipeline') },
    { value: SOURCE_CHAT, text: s__('PipelineSource|Chat') },
    { value: SOURCE_MERGE_REQUEST_EVENT, text: s__('PipelineSource|Merge request') },
    {
      value: SOURCE_EXTERNAL_PULL_REQUEST_EVENT,
      text: s__('PipelineSource|External Pull Request'),
    },
    { value: SOURCE_UNKNOWN, text: s__('PipelineSource|Unknown') },
  ],
  dateRangeItems: [
    {
      value: DATE_RANGE_LAST_WEEK,
      text: s__('PipelineCharts|Last week'),
    },
    {
      value: DATE_RANGE_LAST_30_DAYS,
      text: s__('PipelineCharts|Last 30 days'),
    },
    {
      value: DATE_RANGE_LAST_90_DAYS,
      text: s__('PipelineCharts|Last 90 days'),
    },
    {
      value: DATE_RANGE_LAST_180_DAYS,
      text: s__('PipelineCharts|Last 180 days'),
    },
  ],
};
</script>
<template>
  <div>
    <dashboard-header>
      {{ s__('PipelineCharts|Pipelines') }}
    </dashboard-header>
    <div class="gl-mb-4 gl-flex gl-gap-4 gl-bg-subtle gl-p-4 gl-pb-2">
      <gl-form-group
        class="gl-min-w-20"
        :label="s__('PipelineCharts|Source')"
        label-for="pipeline-source"
      >
        <gl-collapsible-listbox
          id="pipeline-source"
          v-model="source"
          block
          :items="$options.pipelineSources"
        />
      </gl-form-group>
      <gl-form-group class="gl-min-w-15" :label="__('Date range')" label-for="date-range">
        <gl-collapsible-listbox
          id="date-range"
          v-model="dateRange"
          block
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
