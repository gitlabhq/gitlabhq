/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueWarningScope = Vue.extend({
    components: {
      'vue-warning-icon': gl.VueWarningIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-warning">
            <vue-warning-icon></vue-warning-icon>
            &nbsp;warning
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
