/**
 * Render environments table.
 */
const Vue = require('vue');
const EnvironmentItem = require('./environment_item');
const DeployBoard = require('./deploy_board_component');
module.exports = Vue.component('environment-table-component', {

  components: {
    'environment-item': EnvironmentItem,
    'deploy-board': DeployBoard,
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

    commitIconSvg: {
      type: String,
      required: false,
    },

    playIconSvg: {
      type: String,
      required: false,
    },

    terminalIconSvg: {
      type: String,
      required: false,
    },

    toggleDeployBoard: {
      type: Function,
      required: false,
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
            :can-read-environment="canReadEnvironment"
            :play-icon-svg="playIconSvg"
            :terminal-icon-svg="terminalIconSvg"
            :commit-icon-svg="commitIconSvg"
            :toggleDeployBoard="toggleDeployBoard.bind(model)"></tr>

          <tr v-if="model.isDeployBoardVisible">
            <td colspan="6" class="deploy-board-container">
              <deploy-board></deploy-board>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  `,
});
