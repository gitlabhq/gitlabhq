/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStages = Vue.extend({
    components: {
      'vue-stage': gl.VueStage,
    },
    props: ['pipeline'],
    template: `
      <td class="stage-cell">
        <div
          class="stage-container"
          v-for='stage in pipeline.details.stages'
        >
          <vue-stage :stage='stage'></vue-stage>
        </div>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
