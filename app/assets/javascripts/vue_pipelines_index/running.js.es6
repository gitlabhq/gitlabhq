/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueRunningPipeline = Vue.extend({
    components: {
      'vue-running-icon': gl.VueRunningIcon,
    },
    props: [
      'pipeline',
      'pipelineurl',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipelineurl(pipeline.id)'>
          <span class="ci-status ci-running">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="14"
              height="14"
              viewBox="0 0 14 14"
            >
              <vue-running-icon></vue-running-icon>
            </svg>
            &nbsp;running
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
