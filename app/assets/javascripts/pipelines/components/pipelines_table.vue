<script>
  import pipelinesTableRowComponent from './pipelines_table_row.vue';

  /**
   * Pipelines Table Component.
   *
   * Given an array of objects, renders a table.
   */
  export default {
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
    },
    components: {
      pipelinesTableRowComponent,
    },
  };
</script>
<template>
  <div class="ci-table">
    <div
      class="gl-responsive-table-row table-row-header"
      role="row">
      <div
        class="table-section section-5 js-pipeline-status pipeline-id"
        role="rowheader">
        Pipeline
      </div>
      <div
        class="table-section section-10 js-pipeline-status pipeline-status"
        role="rowheader">

      </div>
      <div
        class="table-section section-5 js-pipeline-info pipeline-info"
        role="rowheader">

      </div>
      <div
        class="table-section section-25 js-pipeline-commit pipeline-commit"
        role="rowheader">
        
      </div>
      <div
        class="table-section section-15 js-pipeline-stages pipeline-stages"
        role="rowheader">
        Stages
      </div>
    </div>
    <pipelines-table-row-component
      v-for="model in pipelines"
      :key="model.id"
      :pipeline="model"
      :update-graph-dropdown="updateGraphDropdown"
    />
  </div>
</template>
