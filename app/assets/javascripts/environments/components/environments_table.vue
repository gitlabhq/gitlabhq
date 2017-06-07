<script>
/**
 * Render environments table.
 */
import EnvironmentTableRowComponent from './environment_item.vue';
import DeployBoard from './deploy_board_component.vue';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    'environment-item': EnvironmentTableRowComponent,
    DeployBoard,
    loadingIcon,
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

    isLoadingFolderContent: {
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
      required: true,
    },
  },

  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
  },
};
</script>
<template>
  <div class="ci-table" role="grid">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10 environments-name" role="rowheader">
        Environment
      </div>
      <div class="table-section section-10 environments-deploy" role="rowheader">
        Deployment
      </div>
      <div class="table-section section-15 environments-build" role="rowheader">
        Job
      </div>
      <div class="table-section section-25 environments-commit" role="rowheader">
        Commit
      </div>
      <div class="table-section section-10 environments-date" role="rowheader">
        Updated
      </div>
    </div>
    <template
      v-for="model in environments"
      v-bind:model="model">
      <div
        is="environment-item"
        :model="model"
        :can-create-deployment="canCreateDeployment"
        :can-read-environment="canReadEnvironment"
        :toggleDeployBoard="toggleDeployBoard"
        />

      <div v-if="model.hasDeployBoard && model.isDeployBoardVisible" class="js-deploy-board-row">
        <div class="deploy-board-container">
          <deploy-board
            :store="store"
            :service="service"
            :environmentID="model.id"
            :deployBoardData="model.deployBoardData"
            :endpoint="model.rollout_status_path"
            />
        </div>
      </div>

      <template v-if="model.isFolder && model.isOpen && model.children && model.children.length > 0">
        <div v-if="isLoadingFolderContent">
          <loading-icon size="2" />
        </div>

        <template v-else>
          <div
            is="environment-item"
            v-for="children in model.children"
            :model="children"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"
            />

          <div>
            <div class="text-center prepend-top-10">
              <a
                :href="folderUrl(model)"
                class="btn btn-default">
                Show all
              </a>
            </div>
          </div>
        </template>
      </template>
    </template>
  </div>
</template>
