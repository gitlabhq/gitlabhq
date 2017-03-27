/**
 * Render environments table.
 */
import EnvironmentTableRowComponent from './environment_item';

export default {
  components: {
    'environment-item': EnvironmentTableRowComponent,
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

    service: {
      type: Object,
      required: true,
    },
  },

  template: `
    <table class="table ci-table">
      <thead>
        <tr>
          <th class="environments-name">Environment</th>
          <th class="environments-deploy">Last deployment</th>
          <th class="environments-build">Job</th>
          <th class="environments-commit">Commit</th>
          <th class="environments-date">Updated</th>
          <th class="environments-actions"></th>
        </tr>
      </thead>
      <tbody>
        <template v-for="model in environments"
          v-bind:model="model">
          <tr is="environment-item"
            :model="model"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"
            :service="service"></tr>

          <tr v-if="model.isOpen && model.children && model.children.length > 0"
            is="environment-item"
            v-for="children in model.children"
            :model="children"
            :toggleRow="toggleRow.bind(children)"
            :can-create-deployment="canCreateDeploymentParsed"
            :can-read-environment="canReadEnvironmentParsed"
            :service="service"></tr>
        </template>
      </tbody>
    </table>
  `,
};
