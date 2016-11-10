/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueRunningScope = Vue.extend({
    components: {
      'vue-running-icon': gl.VueRunningIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-running">
            <vue-running-icon></vue-running-icon>
            &nbsp;running
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
