<script>
import { GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { PIPELINE_ID_KEY, PIPELINE_IID_KEY, TRACKING_CATEGORIES } from '~/ci/constants';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import PipelineOperations from '../pipelines_page/components/pipeline_operations.vue';
import PipelineTriggerer from '../pipelines_page/components/pipeline_triggerer.vue';
import PipelineUrl from '../pipelines_page/components/pipeline_url.vue';
import PipelineStatusBadge from '../pipelines_page/components/pipeline_status_badge.vue';

const HIDE_TD_ON_MOBILE = '!gl-hidden lg:!gl-table-cell';

/**
 * Pipelines Table
 *
 * Presentational component of a table of pipelines. This component does not
 * fetch the list of pipelines and instead expects it as a prop.
 * GraphQL actions for pipelines, such as retrying, canceling, etc.
 * are handled within this component.
 *
 * Use this `legacy_pipelines_table_wrapper` if you need a fully functional REST component.
 *
 * IMPORTANT: When using this component, make sure to handle the following events:
 * 1- @refresh-pipeline-table
 * 2- @cancel-pipeline
 * 3- @retry-pipeline
 *
 */

export default {
  components: {
    GlTableLite,
    LegacyPipelineMiniGraph,
    PipelineFailedJobsWidget,
    PipelineOperations,
    PipelineStatusBadge,
    PipelineTriggerer,
    PipelineUrl,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: {
    useFailedJobsWidget: {
      default: false,
    },
  },
  props: {
    pipelines: {
      type: Array,
      required: true,
    },
    updateGraphDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelineIdType: {
      type: String,
      required: false,
      default: PIPELINE_ID_KEY,
      validator(value) {
        return value === PIPELINE_IID_KEY || value === PIPELINE_ID_KEY;
      },
    },
  },
  computed: {
    tableFields() {
      return [
        {
          key: 'status',
          label: s__('Pipeline|Status'),
          columnClass: 'gl-w-3/20',
          tdClass: this.tdClasses,
          thAttr: { 'data-testid': 'status-th' },
        },
        {
          key: 'pipeline',
          label: __('Pipeline'),
          tdClass: `${this.tdClasses}`,
          columnClass: 'gl-w-6/20',
          thAttr: { 'data-testid': 'pipeline-th' },
        },
        {
          key: 'triggerer',
          label: s__('Pipeline|Created by'),
          tdClass: `${this.tdClasses} ${HIDE_TD_ON_MOBILE}`,
          columnClass: 'gl-w-3/20',
          thAttr: { 'data-testid': 'triggerer-th' },
        },
        {
          key: 'stages',
          label: s__('Pipeline|Stages'),
          tdClass: this.tdClasses,
          columnClass: 'gl-w-5/20',
          thAttr: { 'data-testid': 'stages-th' },
        },
        {
          key: 'actions',
          tdClass: this.tdClasses,
          columnClass: 'gl-w-4/20',
          thAttr: { 'data-testid': 'actions-th' },
        },
      ];
    },
    tdClasses() {
      return this.useFailedJobsWidget ? 'gl-pb-0! gl-border-none!' : 'pl-p-5!';
    },
    pipelinesWithDetails() {
      if (this.useFailedJobsWidget) {
        return this.pipelines.map((p) => {
          return { ...p, _showDetails: true };
        });
      }

      return this.pipelines;
    },
  },
  methods: {
    getDownstreamPipelines(pipeline) {
      const downstream = pipeline.triggered;
      return keepLatestDownstreamPipelines(downstream);
    },
    getProjectPath(item) {
      return cleanLeadingSeparator(item.project.full_path);
    },
    getStages(item) {
      return item?.details?.stages || [];
    },
    failedJobsCount(pipeline) {
      return pipeline?.failed_builds_count || 0;
    },
    onRefreshPipelinesTable() {
      this.$emit('refresh-pipelines-table');
    },
    onRetryPipeline(pipeline) {
      this.$emit('retry-pipeline', pipeline);
    },
    onCancelPipeline(pipeline) {
      this.$emit('cancel-pipeline', pipeline);
    },
    trackPipelineMiniGraph() {
      this.track('click_minigraph', { label: TRACKING_CATEGORIES.table });
    },
  },
  TBODY_TR_ATTR: {
    'data-testid': 'pipeline-table-row',
  },
};
</script>
<template>
  <div class="ci-table">
    <gl-table-lite
      :fields="tableFields"
      :items="pipelinesWithDetails"
      :tbody-tr-attr="$options.TBODY_TR_ATTR"
      stacked="lg"
      fixed
    >
      <template #head(actions)>
        <span class="gl-block lg:!gl-hidden">{{ s__('Pipeline|Actions') }}</span>
        <slot name="table-header-actions"></slot>
      </template>

      <template #table-colgroup="{ fields }">
        <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
      </template>

      <template #cell(status)="{ item }">
        <pipeline-status-badge :pipeline="item" />
      </template>

      <template #cell(pipeline)="{ item }">
        <pipeline-url
          :pipeline="item"
          :pipeline-id-type="pipelineIdType"
          ref-color="gl-text-black-normal"
        />
      </template>

      <template #cell(triggerer)="{ item }">
        <pipeline-triggerer :pipeline="item" />
      </template>

      <template #cell(stages)="{ item }">
        <legacy-pipeline-mini-graph
          :downstream-pipelines="getDownstreamPipelines(item)"
          :pipeline-path="item.path"
          :stages="getStages(item)"
          :update-dropdown="updateGraphDropdown"
          :upstream-pipeline="item.triggered_by"
          @miniGraphStageClick="trackPipelineMiniGraph"
        />
      </template>

      <template #cell(actions)="{ item }">
        <pipeline-operations
          :pipeline="item"
          @cancel-pipeline="onCancelPipeline"
          @refresh-pipelines-table="onRefreshPipelinesTable"
          @retry-pipeline="onRetryPipeline"
        />
      </template>

      <template #row-details="{ item }">
        <pipeline-failed-jobs-widget
          v-if="useFailedJobsWidget"
          :failed-jobs-count="failedJobsCount(item)"
          :is-pipeline-active="item.active"
          :pipeline-iid="item.iid"
          :pipeline-path="item.path"
          :project-path="getProjectPath(item)"
          class="-gl-ml-4 -gl-mt-3 -gl-mb-1"
        />
      </template>
    </gl-table-lite>
  </div>
</template>
