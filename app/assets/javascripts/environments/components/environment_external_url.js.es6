/*= require vue */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.ExternalUrlComponent = Vue.component('external-url-component', {
    props: {
      externalUrl: {
        type: String,
        default: '',
      },
    },

    template: `
      <a class="btn external_url" :href="externalUrl" target="_blank">
        <i class="fa fa-external-link"></i>
      </a>
    `,
  });
})();
