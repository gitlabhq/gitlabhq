/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePipelineUrl = Vue.extend({
    props: [
      'pipeline',
    ],
    computed: {
      user() {
        return !!this.pipeline.user;
      },
    },
    template: `
      <td>
        <a :href='pipeline.path'>
          <span class="pipeline-id">#{{pipeline.id}}</span>
        </a>
        <span>by</span>
        <a
          v-if='user'
          :href='pipeline.user.web_url'
        >
          <img
            v-if='user'
            class="avatar has-tooltip s20 "
            :title='pipeline.user.name'
            data-container="body"
            :src='pipeline.user.avatar_url'
          >
        </a>
        <span
          v-if='!user'
          class="api monospace"
        >
          API
        </span>
        <span
          v-if='pipeline.flags.latest'
          class="label label-success has-tooltip"
          title="Latest pipeline for this branch"
          data-original-title="Latest pipeline for this branch"
        >
          latest
        </span>
        <span
          v-if='pipeline.flags.yaml_errors'
          class="label label-danger has-tooltip"
          :title='pipeline.yaml_errors'
          :data-original-title='pipeline.yaml_errors'
        >
          yaml invalid
        </span>
        <span
          v-if='pipeline.flags.stuck'
          class="label label-warning"
        >
          stuck
        </span>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
