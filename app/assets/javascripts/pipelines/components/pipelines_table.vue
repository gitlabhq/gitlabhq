<script>
  import modal from '~/vue_shared/components/modal.vue';
  import { s__, sprintf } from '~/locale';
  import pipelinesTableRowComponent from './pipelines_table_row.vue';
  import eventHub from '../event_hub';

  /**
   * Pipelines Table Component.
   *
   * Given an array of objects, renders a table.
   */
  export default {
    components: {
      pipelinesTableRowComponent,
      modal,
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
        type: '',
      };
    },
    computed: {
      modalTitle() {
        return this.type === 'stop' ?
          sprintf(s__('Pipeline|Stop pipeline #%{pipelineId}?'), {
            pipelineId: `'${this.pipelineId}'`,
          }, false) :
          sprintf(s__('Pipeline|Retry pipeline #%{pipelineId}?'), {
            pipelineId: `'${this.pipelineId}'`,
          }, false);
      },
      modalText() {
        return this.type === 'stop' ?
          sprintf(s__('Pipeline|You’re about to stop pipeline %{pipelineId}.'), {
            pipelineId: `<strong>#${this.pipelineId}</strong>`,
          }, false) :
          sprintf(s__('Pipeline|You’re about to retry pipeline %{pipelineId}.'), {
            pipelineId: `<strong>#${this.pipelineId}</strong>`,
          }, false);
      },
      primaryButtonLabel() {
        return this.type === 'stop' ? s__('Pipeline|Stop pipeline') : s__('Pipeline|Retry pipeline');
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
        this.type = data.type;
      },
      onSubmit() {
        eventHub.$emit('postAction', this.endpoint);
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
    />
    <modal
      id="confirmation-modal"
      :title="modalTitle"
      :text="modalText"
      kind="danger"
      :primary-button-label="primaryButtonLabel"
      @submit="onSubmit"
    >
      <template
        slot="body"
        slot-scope="props"
      >
        <p v-html="props.text"></p>
      </template>
    </modal>
  </div>
</template>
