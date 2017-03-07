/**
 * Renders the external url link in environments table.
 */
const Vue = require('vue');

module.exports = Vue.component('external-url-component', {
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
