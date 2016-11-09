/*= require vue
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  window.gl.environmentsList.StopComponent = Vue.component('stop-component', {
    props: {
      stop_url: {
        type: String,
        default: '',
      },
    },

    template: `
      <a class="btn stop-env-link" 
        :href="stop_url" 
        method="post"
        rel="nofollow", 
        data-confirm="Are you sure you want to stop this environment?">
        <i class="fa fa-stop stop-env-icon"></i>
      </a>
    `,
  });
})();
