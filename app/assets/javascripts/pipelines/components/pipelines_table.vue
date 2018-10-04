<script>
import Modal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf } from '~/locale';
import PipelinesTableRowComponent from './pipelines_table_row.vue';
import eventHub from '../event_hub';

/**
 * Pipelines Table Component.
 *
 * Given an array of objects, renders a table.
 */
export default {
  components: {
    PipelinesTableRowComponent,
    Modal,
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
      pipelineId: '',
      endpoint: '',
      cancelingPipeline: null,
    };
  },
  computed: {
    modalTitle() {
      return sprintf(
        s__('Pipeline|Stop pipeline #%{pipelineId}?'),
        {
          pipelineId: `${this.pipelineId}`,
        },
        false,
      );
    },
    modalText() {
      return sprintf(
        s__('Pipeline|You’re about to stop pipeline %{pipelineId}.'),
        {
          pipelineId: `<strong>#${this.pipelineId}</strong>`,
        },
        false,
      );
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
      this.pipelineId = data.pipelineId;
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
    <div
      class="gl-responsive-table-row table-row-header"
      role="row"
    >
      <div
        class="table-section section-10 js-pipeline-status pipeline-status"
        role="rowheader"
      >
        Status
      </div>
      <div
        class="table-section section-15 js-pipeline-info pipeline-info"
        role="rowheader"
      >
        Pipeline
      </div>
      <div
        class="table-section section-20 js-pipeline-commit pipeline-commit"
        role="rowheader"
      >
        Commit
      </div>
      <div
        class="table-section section-20 js-pipeline-stages pipeline-stages"
        role="rowheader"
      >
        Stages
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

    <modal
      id="confirmation-modal"
      :header-title-text="modalTitle"
      :footer-primary-button-text="s__('Pipeline|Stop pipeline')"
      footer-primary-button-variant="danger"
      @submit="onSubmit"
    >
      <span v-html="modalText"></span>
    </modal>

  </div>
</template>
