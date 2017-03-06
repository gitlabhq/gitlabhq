/**
 * Render environments table.
 *
 * Dumb component used to render top level environments and
 * the folder view.
 */
const Vue = require('vue');
const EnvironmentItem = require('./environment_item');
const DeployBoard = require('./deploy_board_component').default;

module.exports = Vue.component('environment-table-component', {

  components: {
    EnvironmentItem,
    DeployBoard,
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

    toggleDeployBoard: {
      type: Function,
      required: false,
      default: () => {},
    },

    store: {
      type: Object,
      required: false,
      default: () => ({}),
    },

    service: {
      type: Object,
      required: false,
      default: () => ({}),
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
            :toggleDeployBoard="toggleDeployBoard"></tr>

          <tr v-if="model.hasDeployBoard && model.isDeployBoardVisible" class="js-deploy-board-row">
            <td colspan="6" class="deploy-board-container">
              <deploy-board
                :store="store"
                :service="service"
                :environmentID="model.id"
                :deployBoardData="model.deployBoardData"
                :endpoint="model.rollout_status_path">
              </deploy-board>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  `,
});
