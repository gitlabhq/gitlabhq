<script>
import { GlTable, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../../event_hub';
import PipelineMiniGraph from './pipeline_mini_graph.vue';
import PipelineOperations from './pipeline_operations.vue';
import PipelineStopModal from './pipeline_stop_modal.vue';
import PipelineTriggerer from './pipeline_triggerer.vue';
import PipelineUrl from './pipeline_url.vue';
import PipelinesCommit from './pipelines_commit.vue';
import PipelinesStatusBadge from './pipelines_status_badge.vue';
import PipelinesTimeago from './time_ago.vue';

const DEFAULT_TD_CLASS = 'gl-p-5!';
const HIDE_TD_ON_MOBILE = 'gl-display-none! gl-lg-display-table-cell!';
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-p-5! gl-border-b-1! gl-font-sm!';

export default {
  components: {
    GlTable,
    LinkedPipelinesMiniList: () =>
      import('ee_component/vue_shared/components/linked_pipelines_mini_list.vue'),
    PipelinesCommit,
    PipelineMiniGraph,
    PipelineOperations,
    PipelinesStatusBadge,
    PipelineStopModal,
    PipelinesTimeago,
    PipelineTriggerer,
    PipelineUrl,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  data() {
    return {
      pipelineId: 0,
      pipeline: {},
      endpoint: '',
      cancelingPipeline: null,
    };
  },
  computed: {
    tableFields() {
      const fields = [
        {
          key: 'status',
          label: s__('Pipeline|Status'),
          thClass: DEFAULT_TH_CLASSES,
          columnClass: 'gl-w-10p',
          tdClass: DEFAULT_TD_CLASS,
          thAttr: { 'data-testid': 'status-th' },
        },
        {
          key: 'pipeline',
          label: this.pipelineKeyOption.label,
          thClass: DEFAULT_TH_CLASSES,
          tdClass: `${DEFAULT_TD_CLASS} ${HIDE_TD_ON_MOBILE}`,
          columnClass: 'gl-w-10p',
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
          key: 'commit',
          label: s__('Pipeline|Commit'),
          thClass: DEFAULT_TH_CLASSES,
          tdClass: DEFAULT_TD_CLASS,
          columnClass: 'gl-w-20p',
          thAttr: { 'data-testid': 'commit-th' },
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
          key: 'timeago',
          label: s__('Pipeline|Duration'),
          thClass: DEFAULT_TH_CLASSES,
          tdClass: DEFAULT_TD_CLASS,
          columnClass: 'gl-w-15p',
          thAttr: { 'data-testid': 'timeago-th' },
        },
        {
          key: 'actions',
          thClass: DEFAULT_TH_CLASSES,
          tdClass: DEFAULT_TD_CLASS,
          columnClass: 'gl-w-15p',
          thAttr: { 'data-testid': 'actions-th' },
        },
      ];
      return fields;
    },
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
    setModalData(data) {
      this.pipelineId = data.pipeline.id;
      this.pipeline = data.pipeline;
      this.endpoint = data.endpoint;
    },
    onSubmit() {
      eventHub.$emit('postAction', this.endpoint);
      this.cancelingPipeline = this.pipelineId;
    },
    onPipelineActionRequestComplete() {
      eventHub.$emit('refreshPipelinesTable');
    },
  },
};
</script>
<template>
  <div class="ci-table">
    <gl-table
      :fields="tableFields"
      :items="pipelines"
      tbody-tr-class="commit"
      :tbody-tr-attr="{ 'data-testid': 'pipeline-table-row' }"
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
          :pipeline-key="pipelineKeyOption.key"
        />
      </template>

      <template #cell(triggerer)="{ item }">
        <pipeline-triggerer :pipeline="item" />
      </template>

      <template #cell(commit)="{ item }">
        <pipelines-commit :pipeline="item" :view-type="viewType" />
      </template>

      <template #cell(stages)="{ item }">
        <div class="stage-cell">
          <!-- This empty div should be removed, see https://gitlab.com/gitlab-org/gitlab/-/issues/323488 -->
          <div></div>
          <linked-pipelines-mini-list
            v-if="item.triggered_by"
            :triggered-by="[item.triggered_by]"
            data-testid="mini-graph-upstream"
          />
          <pipeline-mini-graph
            v-if="item.details && item.details.stages && item.details.stages.length > 0"
            class="gl-display-inline"
            :stages="item.details.stages"
            :update-dropdown="updateGraphDropdown"
            @pipelineActionRequestComplete="onPipelineActionRequestComplete"
          />
          <linked-pipelines-mini-list
            v-if="item.triggered.length"
            :triggered="item.triggered"
            data-testid="mini-graph-downstream"
          />
        </div>
      </template>

      <template #cell(timeago)="{ item }">
        <pipelines-timeago :pipeline="item" />
      </template>

      <template #cell(actions)="{ item }">
        <pipeline-operations :pipeline="item" :canceling-pipeline="cancelingPipeline" />
      </template>
    </gl-table>

    <pipeline-stop-modal :pipeline="pipeline" @submit="onSubmit" />
  </div>
</template>
