/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineUrl = Vue.extend({
    components: {
      'vue-running-icon': gl.VueRunningIcon,
    },
    props: [
      'pipeline',
    ],
    computed: {
      user() {
        if (!this.pipeline.user) return 'API';
        return this.pipeline.user;
      },
    },
    template: `
      <td>
        <a :href='pipeline.url'>
          <span class="pipeline-id">#{{pipeline.id}}</span>
        </a>
        <span>by</span>
        <span class="api monospace">{{user}}</span>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
