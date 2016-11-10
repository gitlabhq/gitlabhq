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

    methods: {
      openConfirmDialog() {
        return window.confirm('Are you sure you want to stop this environment?');
      },
    },

    template: `
      <a v-on:click="openConfirmDialog"
        class="btn stop-env-link"
        :href="stop_url"
        method="post"
        rel="nofollow">
        <i class="fa fa-stop stop-env-icon"></i>
      </a>
    `,
  });
})();
