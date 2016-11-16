/*= require vue */
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

    computed: {
      stopUrl() {
        return `${this.stop_url}/stop`;
      },
    },

    methods: {
      openConfirmDialog() {
        return window.confirm('Are you sure you want to stop this environment?'); // eslint-disable-line
      },
    },

    template: `
      <a v-on:click="openConfirmDialog"
        class="btn stop-env-link"
        :href="stopUrl"
        data-method="post"
        data-rel="nofollow">
        <i class="fa fa-stop stop-env-icon"></i>
      </a>
    `,
  });
})();
