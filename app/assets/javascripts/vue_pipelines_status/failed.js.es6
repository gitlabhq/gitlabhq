/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueFailedScope = Vue.extend({
    components: {
      'vue-failed-icon': gl.VueFailedIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-failed">
            <vue-failed-icon></vue-failed-icon>
            &nbsp;failed
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
