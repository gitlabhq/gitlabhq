/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueCanceledScope = Vue.extend({
    components: {
      'vue-canceled-icon': gl.VueCanceledIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-cancelled">
            <vue-canceled-icon></vue-canceled-icon>
            &nbsp;cancelled
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
