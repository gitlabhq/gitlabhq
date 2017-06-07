import PipelinesTableRowComponent from './pipelines_table_row';

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

    service: {
      type: Object,
      required: true,
    },

    updateGraphDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  components: {
    'pipelines-table-row-component': PipelinesTableRowComponent,
  },

  template: `
    <div class="ci-table">
      <div class="gl-responsive-table-row table-row-header" role="row">
        <div class="table-section section-10 js-pipeline-status pipeline-status" role="rowheader">Status</div>
        <div class="table-section section-15 js-pipeline-info pipeline-info" role="rowheader">Pipeline</div>
        <div class="table-section section-25 js-pipeline-commit pipeline-commit" role="rowheader">Commit</div>
        <div class="table-section section-15 js-pipeline-stages pipeline-stages" role="rowheader">Stages</div>
      </div>
      <template v-for="model in pipelines"
        v-bind:model="model">
        <div is="pipelines-table-row-component"
          :pipeline="model"
          :service="service"
          :update-graph-dropdown="updateGraphDropdown"
          />
      </template>
    </div>
  `,
};
