/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VuePendingScope = Vue.extend({
    components: {
      'vue-pending-icon': gl.VuePendingIcon,
    },
    props: [
      'scope',
      'scopeurl',
    ],
    template: `
      <td class="commit-link">
        <a :href='scopeurl(scope.id)'>
          <span class="ci-status ci-pending">
            <vue-pending-icon></vue-pending-icon>
            &nbsp;pending
          </span>
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));