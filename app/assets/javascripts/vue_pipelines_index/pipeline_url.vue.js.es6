/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineUrl = Vue.extend({
    components: {
      'vue-running-icon': gl.VueRunningIcon,
    },
    props: [
      'pipeline',
      'pipelineurl',
    ],
    template: `
      <td>
        <a :href='pipelineurl(pipeline.id)'>
          <span class="pipeline-id">#{{pipeline.id}}</span>
        </a>
        <span>by</span>
        <span class="api monospace">{{pipeline.user}}</span>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
