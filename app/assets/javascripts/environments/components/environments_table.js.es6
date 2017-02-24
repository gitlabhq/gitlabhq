/**
 * Render environments table.
 */
const Vue = require('vue');
const EnvironmentItem = require('./environment_item');

module.exports = Vue.component('environment-table-component', {

  components: {
    'environment-item': EnvironmentItem,
  },

  props: {
    environments: {
      type: Array,
      required: true,
      default: () => ([]),
    },

    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },

    canCreateDeployment: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  template: `
    <table class="table ci-table environments">
      <thead>
        <tr>
          <th class="environments-name">Environment</th>
          <th class="environments-deploy">Last deployment</th>
          <th class="environments-build">Job</th>
          <th class="environments-commit">Commit</th>
          <th class="environments-date">Updated</th>
          <th class="hidden-xs environments-actions"></th>
        </tr>
      </thead>
      <tbody>
        <template v-for="model in environments"
          v-bind:model="model">
          <tr is="environment-item"
            :model="model"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"></tr>
        </template>
      </tbody>
    </table>
  `,
});
