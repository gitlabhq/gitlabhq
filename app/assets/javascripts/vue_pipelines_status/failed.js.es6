/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueFailedPipeline = Vue.extend({
    components: {
      'vue-failed-icon': gl.VuePendingIcon,
    },
    props: [
      'pipeline',
      'pipelineurl',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipelineurl(pipeline.id)'>
          <span class="ci-status ci-failed">
            <vue-failed-icon></vue-failed-icon>
            &nbsp;failed
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
