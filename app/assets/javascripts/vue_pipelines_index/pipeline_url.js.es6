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
        <span
          v-if='pipeline.flags.latest === true'
          class="label label-success has-tooltip"
          title=""
          data-original-title="Latest build for this branch"
        >
          latest
        </span>
        <span
          v-if='pipeline.flags.yaml_errors === true'
          class="label label-danger has-tooltip"
          title=""
          data-original-title="Undefined yaml error"
        >
          yaml invalid
        </span>
        <span
        v-if='pipeline.flags.stuck === true'
          class="label label-warning"
        >
          stuck
        </span>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
