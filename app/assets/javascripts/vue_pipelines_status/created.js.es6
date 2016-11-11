/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueCreatedScope = Vue.extend({
    components: {
      'vue-created-icon': gl.VueCreatedIcon,
    },
    props: [
      'pipeline',
    ],
    template: `
      <td class="commit-link">
        <a :href='pipeline.url'>
          <span class="ci-status ci-created">
            <vue-created-icon></vue-created-icon>
            &nbsp;failed
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
