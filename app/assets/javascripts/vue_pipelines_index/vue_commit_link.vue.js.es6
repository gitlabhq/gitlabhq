
/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueCommitLink = Vue.extend({
    props: ['pipeline'],
    template: `
      <td class="commit-link">
        <a href="pipelines/{{pipeline.id}}">
          <div v-if="pipeline.status === 'running'">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
          <div v-if="pipeline.status === 'passed'">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
          <div v-if="pipeline.status === 'created'">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
          <div v-if="pipeline.status === ''">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
          <div v-if="pipeline.status === 'r'">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
          <div v-if="pipeline.status === 'ru'">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
          <div v-if="pipeline.status === 'run'">
            <span class="ci-status ci-{{pipeline.status}}">
              <vue-runner-running></vue-runner-running>
            </span>
          </div>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
