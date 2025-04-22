<script>
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  DATE_RANGE_7_DAYS,
  DATE_RANGE_30_DAYS,
  DATE_RANGE_90_DAYS,
  DATE_RANGE_180_DAYS,
  DATE_RANGE_DEFAULT,
  SOURCE_ANY,
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

import BranchCollapsibleListbox from './branch_collapsible_listbox.vue';

const sourcesItems = [
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
];

const dateRangeItems = [
  { value: DATE_RANGE_7_DAYS, text: s__('PipelineCharts|Last week') },
  { value: DATE_RANGE_30_DAYS, text: s__('PipelineCharts|Last 30 days') },
  { value: DATE_RANGE_90_DAYS, text: s__('PipelineCharts|Last 90 days') },
  { value: DATE_RANGE_180_DAYS, text: s__('PipelineCharts|Last 180 days') },
];

export default {
  name: 'PipelinesDashboardClickhouseFilters',
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    BranchCollapsibleListbox,
  },
  props: {
    value: {
      type: Object,
      default: () => ({
        source: SOURCE_ANY,
        dateRange: DATE_RANGE_7_DAYS,
        branch: null,
      }),
      required: false,
    },
    defaultBranch: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
    projectBranchCount: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  data() {
    const { source, branch, dateRange } = this.value;

    const isValidSource = sourcesItems.map(({ value }) => value).includes(source);
    const isValidDateRange = dateRangeItems.map(({ value }) => value).includes(dateRange);

    return {
      params: {
        source: isValidSource ? source : SOURCE_ANY,
        dateRange: isValidDateRange ? dateRange : DATE_RANGE_DEFAULT,
        branch: branch || this.defaultBranch,
      },
    };
  },
  watch: {
    params: {
      handler(params) {
        this.$emit('input', params);
      },
      deep: true,
    },
  },
  sourcesItems,
  dateRangeItems,
};
</script>
<template>
  <div class="gl-mb-4 gl-flex gl-flex-wrap gl-gap-4 gl-bg-subtle gl-p-4 gl-pb-2">
    <gl-form-group
      class="gl-min-w-full sm:gl-min-w-20"
      :label="s__('PipelineCharts|Source')"
      label-for="pipeline-source"
    >
      <gl-collapsible-listbox
        id="pipeline-source"
        v-model="params.source"
        block
        :items="$options.sourcesItems"
      />
    </gl-form-group>
    <gl-form-group class="gl-min-w-full sm:gl-min-w-26" :label="__('Branch')" label-for="branch">
      <branch-collapsible-listbox
        id="branch"
        v-model="params.branch"
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
        v-model="params.dateRange"
        block
        :items="$options.dateRangeItems"
      />
    </gl-form-group>
  </div>
</template>
