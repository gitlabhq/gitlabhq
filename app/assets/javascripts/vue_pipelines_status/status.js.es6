/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStatusScope = Vue.extend({
    components: {
      'vue-running-scope': gl.VueRunningScope,
      'vue-pending-scope': gl.VuePendingScope,
      'vue-failed-scope': gl.VueFailedScope,
    },
    props: [
      'scope',
      'scopeurl',
    ],
    template: `
      <td class="commit-link">
        <vue-running-scope
          v-if="scope.status === 'running'"
          :scope='scope'
          :scopeurl='scopeurl'
        >
        </vue-running-scope>
        <vue-pending-scope
          v-if="scope.status === 'pending'"
          :scope='scope'
          :scopeurl='scopeurl'
        >
        </vue-pending-scope>
        <vue-failed-scope
          v-if="scope.status === 'failed'"
          :scope='scope'
          :scopeurl='scopeurl'
        >
        </vue-failed-scope>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
