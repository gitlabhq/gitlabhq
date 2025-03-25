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
  SOURCE_PUSH,
  SOURCE_SCHEDULE,
  SOURCE_MERGE_REQUEST_EVENT,
  SOURCE_WEB,
  SOURCE_TRIGGER,
  SOURCE_API,
  SOURCE_EXTERNAL,
  SOURCE_PIPELINE,
  SOURCE_CHAT,
  SOURCE_WEBIDE,
  SOURCE_EXTERNAL_PULL_REQUEST_EVENT,
  SOURCE_PARENT_PIPELINE,
  SOURCE_ONDEMAND_DAST_SCAN,
  SOURCE_ONDEMAND_DAST_VALIDATION,
  SOURCE_SECURITY_ORCHESTRATION_POLICY,
  SOURCE_CONTAINER_REGISTRY_PUSH,
  SOURCE_DUO_WORKFLOW,
  SOURCE_PIPELINE_EXECUTION_POLICY_SCHEDULE,
  SOURCE_UNKNOWN,
} from '../constants';

import getPipelineAnalytics from '../graphql/queries/get_pipeline_analytics.query.graphql';

import DashboardHeader from './dashboard_header.vue';
import BranchCollapsibleListbox from './branch_collapsible_listbox.vue';
import StatisticsList from './statistics_list.vue';
import PipelineDurationChart from './pipeline_duration_chart.vue';
import PipelineStatusChart from './pipeline_status_chart.vue';

const SOURCE_ANY = 'ANY';

export default {
  name: 'PipelinesDashboardClickhouse',
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    DashboardHeader,
    BranchCollapsibleListbox,
    StatisticsList,
    PipelineDurationChart,
    PipelineStatusChart,
  },
  inject: {
    defaultBranch: {
      type: String,
      default: null,
    },
    projectPath: {
      type: String,
      default: '',
    },
    projectBranchCount: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      source: SOURCE_ANY,
      dateRange: DATE_RANGE_LAST_WEEK,
      branch: this.defaultBranch,
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
        branch: this.branch,
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
    { value: SOURCE_ANY, text: s__('PipelineSource|Any source') },
    { value: SOURCE_PUSH, text: s__('PipelineSource|Push') },
    { value: SOURCE_SCHEDULE, text: s__('PipelineSource|Schedule') },
    { value: SOURCE_MERGE_REQUEST_EVENT, text: s__('PipelineSource|Merge Request Event') },
    { value: SOURCE_WEB, text: s__('PipelineSource|Web') },
    { value: SOURCE_TRIGGER, text: s__('PipelineSource|Trigger') },
    { value: SOURCE_API, text: s__('PipelineSource|API') },
    { value: SOURCE_EXTERNAL, text: s__('PipelineSource|External') },
    { value: SOURCE_PIPELINE, text: s__('PipelineSource|Pipeline') },
    { value: SOURCE_CHAT, text: s__('PipelineSource|Chat') },
    { value: SOURCE_WEBIDE, text: s__('PipelineSource|Web IDE') },
    {
      value: SOURCE_EXTERNAL_PULL_REQUEST_EVENT,
      text: s__('PipelineSource|External Pull Request Event'),
    },
    { value: SOURCE_PARENT_PIPELINE, text: s__('PipelineSource|Parent Pipeline') },
    { value: SOURCE_ONDEMAND_DAST_SCAN, text: s__('PipelineSource|On-Demand DAST Scan') },
    {
      value: SOURCE_ONDEMAND_DAST_VALIDATION,
      text: s__('PipelineSource|On-Demand DAST Validation'),
    },
    {
      value: SOURCE_SECURITY_ORCHESTRATION_POLICY,
      text: s__('PipelineSource|Security Orchestration Policy'),
    },
    { value: SOURCE_CONTAINER_REGISTRY_PUSH, text: s__('PipelineSource|Container Registry Push') },
    { value: SOURCE_DUO_WORKFLOW, text: s__('PipelineSource|Duo Workflow') },
    {
      value: SOURCE_PIPELINE_EXECUTION_POLICY_SCHEDULE,
      text: s__('PipelineSource|Pipeline Execution Policy Schedule'),
    },
    { value: SOURCE_UNKNOWN, text: s__('PipelineSource|Unknown') },
  ],
  dateRangeItems: [
    { value: DATE_RANGE_LAST_WEEK, text: s__('PipelineCharts|Last week') },
    { value: DATE_RANGE_LAST_30_DAYS, text: s__('PipelineCharts|Last 30 days') },
    { value: DATE_RANGE_LAST_90_DAYS, text: s__('PipelineCharts|Last 90 days') },
    { value: DATE_RANGE_LAST_180_DAYS, text: s__('PipelineCharts|Last 180 days') },
  ],
};
</script>
<template>
  <div>
    <dashboard-header>
      {{ s__('PipelineCharts|Pipelines') }}
    </dashboard-header>
    <div class="gl-mb-4 gl-flex gl-flex-wrap gl-gap-4 gl-bg-subtle gl-p-4 gl-pb-2">
      <gl-form-group
        class="gl-min-w-full sm:gl-min-w-20"
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
      <gl-form-group class="gl-min-w-full sm:gl-min-w-26" :label="__('Branch')" label-for="branch">
        <branch-collapsible-listbox
          id="branch"
          v-model="branch"
          block
          :default-branch="defaultBranch"
          :project-path="projectPath"
          :project-branch-count="projectBranchCount"
        />
      </gl-form-group>
      <gl-form-group
        class="gl-min-w-full sm:gl-min-w-15"
        :label="__('Date range')"
        label-for="date-range"
      >
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
