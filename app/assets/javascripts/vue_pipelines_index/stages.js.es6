/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStages = Vue.extend({
    components: {
      'vue-stage': gl.VueStage,
    },
    props: ['pipeline', 'svgs', 'match'],
    template: `
      <td class="stage-cell">
        <div
          class="stage-container dropdown js-mini-pipeline-graph"
          v-for='stage in pipeline.details.stages'
        >
          <vue-stage :stage='stage' :svgs='svgs' :match='match'></vue-stage>
        </div>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
