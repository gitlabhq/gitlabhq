/*= require vue */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.RollbackComponent = Vue.component('rollback-component', {
    props: {
      retryUrl: {
        type: String,
        default: '',
      },

      isLastDeployment: {
        type: Boolean,
        default: true,
      },
    },

    template: `
      <a class="btn" :href="retryUrl" data-method="post" rel="nofollow">
        <span v-if="isLastDeployment">
          Re-deploy
        </span>
        <span v-else>
          Rollback
        </span>
      </a>
    `,
  });
})();
