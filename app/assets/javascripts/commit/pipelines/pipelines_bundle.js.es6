/* eslint-disable no-new */
/* global Vue, VueResource */

//= require vue
//= require vue-resource
//= require ./pipelines_store
//= require ./pipelines_service
//= require vue_shared/components/commit
//= require vue_shared/vue_resource_interceptor
//= require vue_shared/components/pipelines_table

/**
 * Commits View > Pipelines Tab > Pipelines Table.
 *
 * Renders Pipelines table in pipelines tab in the commits show view.
 *
 * Uses `pipelines-table-component` to render Pipelines table with an API call.
 * Endpoint is provided in HTML and passed as scope.
 * We need a store to make the request and store the received environemnts.
 *
 * Necessary SVG in the table are provided as props. This should be refactored
 * as soon as we have Webpack and can load them directly into JS files.
 */
(() => {
  window.gl = window.gl || {};
  gl.Commits = gl.Commits || {};

  if (gl.Commits.PipelinesTableView) {
    gl.Commits.PipelinesTableView.$destroy(true);
  }

  gl.Commits.PipelinesTableView = new Vue({

    el: document.querySelector('#commit-pipeline-table-view'),

    /**
     * Accesses the DOM to provide the needed data.
     * Returns the necessary props to render `pipelines-table-component` component.
     *
     * @return {Object} Props for `pipelines-table-component`
     */
    data() {
      const pipelinesTableData = document.querySelector('#commit-pipeline-table-view').dataset;

      return {
        scope: pipelinesTableData.pipelinesData,
        store: new CommitsPipelineStore(),
        service: new PipelinesService(),
        svgs: pipelinesTableData,
      };
    },

    components: {
      'pipelines-table-component': gl.pipelines.PipelinesTableComponent,
    },

    template: `
      <pipelines-table-component :scope='scope' :store='store' :svgs='svgs'></pipelines-table-component>
    `,
  });
});
