/*= require vue
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  window.gl.environmentsList.ExternalUrlComponent = Vue.component('external-url-component', {
    props: {
      external_url: {
        type: String,
        default: '',
      },
    },

    template: `
      <a class="btn external_url":href="external_url" :target="_blank">
        <i class="fa fa-external-link"></i>
      </a>
    `,
  });
})();
