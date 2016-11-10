/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePendingScope = Vue.extend({
    components: {
      'vue-pending-icon': gl.VuePendingIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-pending">
            <vue-pending-icon></vue-pending-icon>
            &nbsp;pending
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));