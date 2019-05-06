<script>
import { GlTooltipDirective } from '@gitlab/ui';
import PipelinesTableRowComponent from './pipelines_table_row.vue';
import PipelineStopModal from './pipeline_stop_modal.vue';
import eventHub from '../event_hub';

/**
 * Pipelines Table Component.
 *
 * Given an array of objects, renders a table.
 */
export default {
  components: {
    PipelinesTableRowComponent,
    PipelineStopModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    autoDevopsHelpPath: {
      type: String,
      required: true,
    },
    viewType: {
      type: String,
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
  },
};
</script>
<template>
  <div class="ci-table">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10 js-pipeline-status" role="rowheader">
        {{ s__('Pipeline|Status') }}
      </div>
      <div class="table-section section-10 js-pipeline-info pipeline-info" role="rowheader">
        {{ s__('Pipeline|Pipeline') }}
      </div>
      <div class="table-section section-10 js-triggerer-info triggerer-info" role="rowheader">
        {{ s__('Pipeline|Triggerer') }}
      </div>
      <div class="table-section section-20 js-pipeline-commit pipeline-commit" role="rowheader">
        {{ s__('Pipeline|Commit') }}
      </div>
      <div class="table-section section-15 js-pipeline-stages pipeline-stages" role="rowheader">
        {{ s__('Pipeline|Stages') }}
      </div>
    </div>
    <pipelines-table-row-component
      v-for="model in pipelines"
      :key="model.id"
      :pipeline="model"
      :update-graph-dropdown="updateGraphDropdown"
      :auto-devops-help-path="autoDevopsHelpPath"
      :view-type="viewType"
      :canceling-pipeline="cancelingPipeline"
    />
    <pipeline-stop-modal :pipeline="pipeline" @submit="onSubmit" />
  </div>
</template>
