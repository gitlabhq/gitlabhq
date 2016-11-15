/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueUnstableScope = Vue.extend({
    components: {
      'vue-unstable-icon': gl.VueUnstableIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-unstable">
            <vue-unstable-icon></vue-unstable-icon>
            &nbsp;unstable
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
