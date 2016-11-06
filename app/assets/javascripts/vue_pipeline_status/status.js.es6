/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStatusPipeline = Vue.extend({
    components: {
      'vue-running-pipeline': gl.VueRunningPipeline,
      'vue-pending-pipeline': gl.VuePendingPipeline,
      'vue-failed-pipeline': gl.VueFailedPipeline,
    },
    props: [
      'pipeline',
      'pipelineurl',
    ],
    template: `
      <td class="commit-link">
        <vue-running-pipeline
          v-if="pipeline.status === 'running'"
          :pipeline='pipeline'
          :pipelineurl='pipelineurl'
        >
        </vue-running-pipeline>
        <vue-pending-pipeline
          v-if="pipeline.status === 'pending'"
          :pipeline='pipeline'
          :pipelineurl='pipelineurl'
        >
        </vue-pending-pipeline>
        <vue-failed-pipeline
          v-if="pipeline.status === 'failed'"
          :pipeline='pipeline'
          :pipelineurl='pipelineurl'
        >
        </vue-failed-pipeline>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
