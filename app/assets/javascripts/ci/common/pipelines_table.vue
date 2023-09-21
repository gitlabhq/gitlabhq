<script>
import { GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TRACKING_CATEGORIES } from '~/ci/constants';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import LegacyPipelineMiniGraph from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph.vue';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import PipelineOperations from '../pipelines_page/components/pipeline_operations.vue';
import PipelineTriggerer from '../pipelines_page/components/pipeline_triggerer.vue';
import PipelineUrl from '../pipelines_page/components/pipeline_url.vue';
import PipelinesStatusBadge from '../pipelines_page/components/pipelines_status_badge.vue';

const HIDE_TD_ON_MOBILE = 'gl-display-none! gl-lg-display-table-cell!';
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-p-5! gl-border-b-1!';

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
    PipelinesStatusBadge,
    PipelineTriggerer,
    PipelineUrl,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin(), glFeatureFlagMixin()],
  inject: {
    withFailedJobsDetails: {
      default: false,
    },
  },
  props: {
    pipelines: {
      type: Array,
      required: true,
    },
    pipelineScheduleUrl: {
      type: String,
      required: false,
      default: '',
    },
    updateGraphDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    viewType: {
      type: String,
      required: true,
    },
    pipelineKeyOption: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showFailedJobsWidget() {
      return this.glFeatures.ciJobFailuresInMr;
    },
    tableFields() {
      return [
        {
          key: 'status',
          label: s__('Pipeline|Status'),
          thClass: DEFAULT_TH_CLASSES,
          columnClass: 'gl-w-15p',
          tdClass: this.tdClasses,
          thAttr: { 'data-testid': 'status-th' },
        },
        {
          key: 'pipeline',
          label: __('Pipeline'),
          thClass: DEFAULT_TH_CLASSES,
          tdClass: `${this.tdClasses}`,
          columnClass: 'gl-w-30p',
          thAttr: { 'data-testid': 'pipeline-th' },
        },
        {
          key: 'triggerer',
          label: s__('Pipeline|Created by'),
          thClass: DEFAULT_TH_CLASSES,
          tdClass: `${this.tdClasses} ${HIDE_TD_ON_MOBILE}`,
          columnClass: 'gl-w-15p',
          thAttr: { 'data-testid': 'triggerer-th' },
        },
        {
          key: 'stages',
          label: s__('Pipeline|Stages'),
          thClass: DEFAULT_TH_CLASSES,
          tdClass: this.tdClasses,
          columnClass: 'gl-w-quarter',
          thAttr: { 'data-testid': 'stages-th' },
        },
        {
          key: 'actions',
          thClass: DEFAULT_TH_CLASSES,
          tdClass: this.tdClasses,
          columnClass: 'gl-w-20p',
          thAttr: { 'data-testid': 'actions-th' },
        },
      ];
    },
    tdClasses() {
      return this.withFailedJobsDetails ? 'gl-pb-0! gl-border-none!' : 'pl-p-5!';
    },
    pipelinesWithDetails() {
      if (this.withFailedJobsDetails) {
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
    failedJobsCount(pipeline) {
      return pipeline?.failed_builds?.length || 0;
    },
    onRefreshPipelinesTable() {
      this.$emit('refresh-pipelines-table');
    },
    onRetryPipeline(pipeline) {
      // This emit is only used by the `legacy_pipelines_table_wrapper`.
      this.$emit('retry-pipeline', pipeline);
    },
    onCancelPipeline(pipeline) {
      // This emit is only used by the `legacy_pipelines_table_wrapper`.
      this.$emit('cancel-pipeline', pipeline);
    },
    trackPipelineMiniGraph() {
      this.track('click_minigraph', { label: TRACKING_CATEGORIES.table });
    },
  },
  TBODY_TR_ATTR: {
    'data-testid': 'pipeline-table-row',
    'data-qa-selector': 'pipeline_row_container',
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
        <span class="gl-display-block gl-lg-display-none!">{{ s__('Pipeline|Actions') }}</span>
        <slot name="table-header-actions"></slot>
      </template>

      <template #table-colgroup="{ fields }">
        <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
      </template>

      <template #cell(status)="{ item }">
        <pipelines-status-badge :pipeline="item" :view-type="viewType" />
      </template>

      <template #cell(pipeline)="{ item }">
        <pipeline-url
          :pipeline="item"
          :pipeline-schedule-url="pipelineScheduleUrl"
          :pipeline-key="pipelineKeyOption.value"
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
          :stages="item.details.stages"
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
          v-if="showFailedJobsWidget"
          :failed-jobs-count="failedJobsCount(item)"
          :is-pipeline-active="item.active"
          :pipeline-iid="item.iid"
          :pipeline-path="item.path"
          :project-path="getProjectPath(item)"
          class="gl-ml-n4 gl-mt-n3 gl-mb-n1"
        />
      </template>
    </gl-table-lite>
  </div>
</template>
