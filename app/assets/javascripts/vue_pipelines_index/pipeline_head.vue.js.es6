/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineHead = Vue.extend({
    components: {
      'vue-running-icon': gl.VueRunningIcon,
    },
    props: [
      'pipeline',
      'pipelineurl',
    ],
    template: `
      <thead>
        <tr>
          <th>Status</th>
          <th>Pipeline</th>
          <th>Commit</th>
          <th>Stages</th>
          <th></th>
          <th class="hidden-xs"></th>
        </tr>
      </thead>
    `,
  });
})(window.gl || (window.gl = {}));
