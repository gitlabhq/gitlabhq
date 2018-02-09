<script>
  import pipelinesTableRowComponent from './pipelines_table_row.vue';
  import stopConfirmationModal from './stop_confirmation_modal.vue';
  import retryConfirmationModal from './retry_confirmation_modal.vue';

  /**
   * Pipelines Table Component.
   *
   * Given an array of objects, renders a table.
   */
  export default {
    components: {
      pipelinesTableRowComponent,
      stopConfirmationModal,
      retryConfirmationModal,
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
    <stop-confirmation-modal />
    <retry-confirmation-modal />
  </div>
</template>
