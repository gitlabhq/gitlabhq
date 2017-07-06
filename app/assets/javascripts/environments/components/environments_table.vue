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
      <div class="table-section section-10 environments-name" role="columnheader">
        Environment
      </div>
      <div class="table-section section-10 environments-deploy" role="columnheader">
        Deployment
      </div>
      <div class="table-section section-15 environments-build" role="columnheader">
        Job
      </div>
      <div class="table-section section-25 environments-commit" role="columnheader">
        Commit
      </div>
      <div class="table-section section-10 environments-date" role="columnheader">
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
        />

      <div v-if="model.hasDeployBoard && model.isDeployBoardVisible" class="js-deploy-board-row">
        <div class="deploy-board-container">
          <deploy-board
            :deploy-board-data="model.deployBoardData"
            :is-loading="model.isLoadingDeployBoard"
            :has-error="model.hasErrorDeployBoard"
            />
        </div>
      </div>

      <template v-if="model.isFolder && model.isOpen && model.children && model.children.length > 0">
        <div v-if="model.isLoadingFolderContent">
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
