<script>
import { GlSkeletonLoader, GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { PIPELINE_ID_KEY, PIPELINE_IID_KEY, TRACKING_CATEGORIES } from '~/ci/constants';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import PipelineFailedJobsWidget from '~/ci/pipelines_page/components/failure_widget/pipeline_failed_jobs_widget.vue';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
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
  name: 'PipelinesTable',
  cellHeight: 50,
  components: {
    GlSkeletonLoader,
    GlTableLite,
    PipelineFailedJobsWidget,
    PipelineMiniGraph,
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
    isCreatingPipeline: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelines: {
      type: Array,
      required: true,
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
    isMobile() {
      return ['md', 'sm', 'xs'].includes(GlBreakpointInstance.getBreakpointSize());
    },
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
      return '!gl-border-none';
    },
    pipelinesWithDetails() {
      let { pipelines } = this;

      if (this.isCreatingPipeline) {
        pipelines = [{ isLoading: true }, ...this.pipelines];
      }

      if (this.useFailedJobsWidget) {
        pipelines = pipelines.map((p) => {
          return p.failed_builds_count > 0 ? { ...p, _showDetails: true } : p;
        });
      }

      return pipelines;
    },
  },
  methods: {
    cellWidth(ref) {
      return this.$refs[ref]?.offsetWidth;
    },
    displayFailedJobsWidget(item) {
      return !item.isLoading && this.useFailedJobsWidget;
    },
    failedJobsCount(pipeline) {
      return pipeline?.failed_builds_count || 0;
    },
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
    onCancelPipeline(pipeline) {
      this.$emit('cancel-pipeline', pipeline);
    },
    onRefreshPipelinesTable() {
      this.$emit('refresh-pipelines-table');
    },
    onRetryPipeline(pipeline) {
      this.$emit('retry-pipeline', pipeline);
    },
    rowClass(item) {
      return this.displayFailedJobsWidget(item) && this.failedJobsCount(item) > 0
        ? ''
        : '!gl-border-b';
    },
    setLoaderPosition(ref) {
      if (this.isMobile) {
        return this.cellWidth(ref) / 2;
      }

      return 0;
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
      :tbody-tr-class="rowClass"
      details-td-class="!gl-pt-2"
      stacked="lg"
      fixed
    >
      <template #head(actions)>
        <slot name="table-header-actions">
          <span class="gl-block gl-text-right">{{ s__('Pipeline|Actions') }}</span>
        </slot>
      </template>

      <template #table-colgroup="{ fields }">
        <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
      </template>

      <template #cell(status)="{ item }">
        <div v-if="item.isLoading" ref="status">
          <gl-skeleton-loader :height="$options.cellHeight" :width="cellWidth('status')">
            <rect height="30" rx="4" ry="4" :width="cellWidth('status')" />
          </gl-skeleton-loader>
        </div>
        <pipeline-status-badge v-else :pipeline="item" />
      </template>

      <template #cell(pipeline)="{ item }">
        <div v-if="item.isLoading" ref="pipeline">
          <gl-skeleton-loader :height="$options.cellHeight" :width="cellWidth('pipeline')">
            <rect height="14" rx="4" ry="4" :width="cellWidth('pipeline')" />
            <rect
              height="10"
              rx="4"
              ry="4"
              :width="cellWidth('pipeline') / 2"
              :x="setLoaderPosition('pipeline')"
              y="20"
            />
          </gl-skeleton-loader>
        </div>
        <pipeline-url
          v-else
          :pipeline="item"
          :pipeline-id-type="pipelineIdType"
          ref-color="gl-text-default"
        />
      </template>

      <template #cell(triggerer)="{ item }">
        <div v-if="item.isLoading" ref="triggerer" class="gl-ml-3">
          <gl-skeleton-loader :height="$options.cellHeight" :width="cellWidth('triggerer')">
            <rect :height="34" rx="50" ry="50" :width="34" />
          </gl-skeleton-loader>
        </div>
        <pipeline-triggerer v-else :pipeline="item" />
      </template>

      <template #cell(stages)="{ item }">
        <div v-if="item.isLoading" ref="stages">
          <gl-skeleton-loader :height="$options.cellHeight" :width="cellWidth('stages')">
            <rect height="20" rx="10" ry="10" :width="cellWidth('stages')" />
          </gl-skeleton-loader>
        </div>
        <pipeline-mini-graph
          v-else
          :downstream-pipelines="getDownstreamPipelines(item)"
          :pipeline-path="item.path"
          :pipeline-stages="getStages(item)"
          :upstream-pipeline="item.triggered_by"
          @miniGraphStageClick="trackPipelineMiniGraph"
        />
      </template>

      <template #cell(actions)="{ item }">
        <div v-if="item.isLoading" ref="actions">
          <gl-skeleton-loader :height="$options.cellHeight" :width="cellWidth('actions')">
            <rect height="20" rx="4" ry="4" :width="cellWidth('actions')" />
          </gl-skeleton-loader>
        </div>
        <pipeline-operations
          v-else
          :pipeline="item"
          @cancel-pipeline="onCancelPipeline"
          @refresh-pipelines-table="onRefreshPipelinesTable"
          @retry-pipeline="onRetryPipeline"
        />
      </template>

      <template #row-details="{ item }">
        <pipeline-failed-jobs-widget
          v-if="displayFailedJobsWidget(item)"
          :pipeline-iid="item.iid"
          :pipeline-path="item.path"
          :project-path="getProjectPath(item)"
          class="-gl-my-3 -gl-ml-4"
        />
      </template>
    </gl-table-lite>
  </div>
</template>
