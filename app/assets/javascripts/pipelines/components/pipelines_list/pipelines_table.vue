<script>
import { GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import Tracking from '~/tracking';
import { keepLatestDownstreamPipelines } from '~/pipelines/components/parsing_utils';
import PipelineMiniGraph from '~/pipelines/components/pipeline_mini_graph/pipeline_mini_graph.vue';
import eventHub from '../../event_hub';
import { TRACKING_CATEGORIES } from '../../constants';
import PipelineOperations from './pipeline_operations.vue';
import PipelineStopModal from './pipeline_stop_modal.vue';
import PipelineTriggerer from './pipeline_triggerer.vue';
import PipelineUrl from './pipeline_url.vue';
import PipelinesStatusBadge from './pipelines_status_badge.vue';

const DEFAULT_TD_CLASS = 'gl-p-5!';
const HIDE_TD_ON_MOBILE = 'gl-display-none! gl-lg-display-table-cell!';
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-p-5! gl-border-b-1!';

export default {
  components: {
    GlTableLite,
    PipelineMiniGraph,
    PipelineOperations,
    PipelinesStatusBadge,
    PipelineStopModal,
    PipelineTriggerer,
    PipelineUrl,
  },
  tableFields: [
    {
      key: 'status',
      label: s__('Pipeline|Status'),
      thClass: DEFAULT_TH_CLASSES,
      columnClass: 'gl-w-15p',
      tdClass: DEFAULT_TD_CLASS,
      thAttr: { 'data-testid': 'status-th' },
    },
    {
      key: 'pipeline',
      label: __('Pipeline'),
      thClass: DEFAULT_TH_CLASSES,
      tdClass: `${DEFAULT_TD_CLASS}`,
      columnClass: 'gl-w-30p',
      thAttr: { 'data-testid': 'pipeline-th' },
    },
    {
      key: 'triggerer',
      label: s__('Pipeline|Triggerer'),
      thClass: DEFAULT_TH_CLASSES,
      tdClass: `${DEFAULT_TD_CLASS} ${HIDE_TD_ON_MOBILE}`,
      columnClass: 'gl-w-10p',
      thAttr: { 'data-testid': 'triggerer-th' },
    },
    {
      key: 'stages',
      label: s__('Pipeline|Stages'),
      thClass: DEFAULT_TH_CLASSES,
      tdClass: DEFAULT_TD_CLASS,
      columnClass: 'gl-w-quarter',
      thAttr: { 'data-testid': 'stages-th' },
    },
    {
      key: 'actions',
      thClass: DEFAULT_TH_CLASSES,
      tdClass: DEFAULT_TD_CLASS,
      columnClass: 'gl-w-15p',
      thAttr: { 'data-testid': 'actions-th' },
    },
  ],
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
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
  data() {
    return {
      pipelineId: 0,
      pipeline: {},
      endpoint: '',
      cancelingPipeline: null,
    };
  },
  watch: {
    pipelines() {
      this.cancelingPipeline = null;
    },
  },
  created() {
    eventHub.$on('openConfirmationModal', this.setModalData);
  },
  beforeDestroy() {
    eventHub.$off('openConfirmationModal', this.setModalData);
  },
  methods: {
    getDownstreamPipelines(pipeline) {
      const downstream = pipeline.triggered;
      return keepLatestDownstreamPipelines(downstream);
    },
    setModalData(data) {
      this.pipelineId = data.pipeline.id;
      this.pipeline = data.pipeline;
      this.endpoint = data.endpoint;
    },
    onSubmit() {
      eventHub.$emit('postAction', this.endpoint);
      this.cancelingPipeline = this.pipelineId;
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
      :fields="$options.tableFields"
      :items="pipelines"
      tbody-tr-class="commit"
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
        />
      </template>

      <template #cell(triggerer)="{ item }">
        <pipeline-triggerer :pipeline="item" />
      </template>

      <template #cell(stages)="{ item }">
        <pipeline-mini-graph
          :downstream-pipelines="getDownstreamPipelines(item)"
          :pipeline-path="item.path"
          :stages="item.details.stages"
          :update-dropdown="updateGraphDropdown"
          :upstream-pipeline="item.triggered_by"
          @miniGraphStageClick="trackPipelineMiniGraph"
        />
      </template>

      <template #cell(actions)="{ item }">
        <pipeline-operations :pipeline="item" :canceling-pipeline="cancelingPipeline" />
      </template>
    </gl-table-lite>

    <pipeline-stop-modal :pipeline="pipeline" @submit="onSubmit" />
  </div>
</template>
