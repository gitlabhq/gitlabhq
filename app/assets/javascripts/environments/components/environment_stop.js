/**
 * Renders the stop "button" that allows stop an environment.
 * Used in environments table.
 */
const Vue = require('vue');

module.exports = Vue.component('stop-component', {
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
      <i class="fa fa-stop stop-env-icon" aria-hidden="true"></i>
    </a>
  `,
});
