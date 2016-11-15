/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueSkippedScope = Vue.extend({
    components: {
      'vue-skipped-icon': gl.VueSkippedIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-skipped">
            <vue-skipped-icon></vue-skipped-icon>
            &nbsp;skipped
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));