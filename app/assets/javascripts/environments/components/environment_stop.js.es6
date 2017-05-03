/*= require vue */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.StopComponent = Vue.component('stop-component', {
    props: {
      stopUrl: {
        type: String,
        default: '',
      },
    },

    template: `
      <a class="btn stop-env-link"
        :href="stopUrl"
        data-confirm="Are you sure you want to stop this environment?"
        data-method="post"
        rel="nofollow">
        <i class="fa fa-stop stop-env-icon"></i>
      </a>
    `,
  });
})();
