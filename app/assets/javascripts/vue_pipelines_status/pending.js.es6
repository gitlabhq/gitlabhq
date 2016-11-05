/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePendingPipeline = Vue.extend({
    components: {
      'vue-pending-icon': gl.VuePendingIcon,
    },
    props: [
      'pipeline',
      'pipelineurl',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipelineurl(pipeline.id)'>
          <span class="ci-status ci-pending">
            <vue-pending-icon></vue-pending-icon>
            &nbsp;pending
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));