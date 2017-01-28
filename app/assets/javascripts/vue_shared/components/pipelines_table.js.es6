/* eslint-disable no-param-reassign */
/* global Vue */

//=require ./pipelines_table_row

/**
 * Pipelines Table Component
 *
 * Given an array of pipelines, renders a table.
 *
 */

(() => {
  window.gl = window.gl || {};
  gl.pipelines = gl.pipelines || {};

  gl.pipelines.PipelinesTableComponent = Vue.component('pipelines-table-component', {

    props: {
      pipelines: {
        type: Array,
        required: true,
        default: [],
      },

      /**
       * Remove this. Find a better way to do this. don't want to provide this 3 times.
       */
      svgs: {
        type: Object,
        required: true,
        default: () => ({}),
      },
    },

    components: {
      'pipelines-table-row-component': gl.pipelines.PipelinesTableRowComponent,
    },

    template: `
      <table class="table ci-table">
        <thead>
          <tr>
            <th class="pipeline-status">Status</th>
            <th class="pipeline-info">Pipeline</th>
            <th class="pipeline-commit">Commit</th>
            <th class="pipeline-stages">Stages</th>
            <th class="pipeline-date"></th>
            <th class="pipeline-actions hidden-xs"></th>
          </tr>
        </thead>
        <tbody>
          <template v-for="model in pipelines"
            v-bind:model="model">
            <tr
              is="pipelines-table-row-component"
              :pipeline="model"
              :svgs="svgs"></tr>
          </template>
        </tbody>
      </table>
    `,
  });
})();
