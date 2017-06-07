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
<<<<<<< HEAD
  <table class="table ci-table">
    <thead>
      <tr>
        <th class="environments-name">
          Environment
        </th>
        <th class="environments-deploy">
          Last deployment
        </th>
        <th class="environments-build">
          Job
        </th>
        <th class="environments-commit">
          Commit
        </th>
        <th class="environments-date">
          Updated
        </th>
        <th class="environments-actions"></th>
      </tr>
    </thead>
    <tbody>
      <template
        v-for="model in environments"
        v-bind:model="model">
        <tr
          is="environment-item"
          :model="model"
          :can-create-deployment="canCreateDeployment"
          :can-read-environment="canReadEnvironment"
          :toggleDeployBoard="toggleDeployBoard"
          />

        <tr v-if="model.hasDeployBoard && model.isDeployBoardVisible" class="js-deploy-board-row">
          <td colspan="6" class="deploy-board-container">
            <deploy-board
              :store="store"
              :service="service"
              :environmentID="model.id"
              :deployBoardData="model.deployBoardData"
              :endpoint="model.rollout_status_path"
              />
          </td>
        </tr>

        <template v-if="model.isFolder && model.isOpen && model.children && model.children.length > 0">
          <tr v-if="isLoadingFolderContent">
            <td colspan="6">
              <loading-icon size="2" />
            </td>
          </tr>
=======
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
        />

      <template v-if="model.isFolder && model.isOpen && model.children && model.children.length > 0">
        <div v-if="isLoadingFolderContent">
          <loading-icon size="2" />
        </div>
>>>>>>> ce/master

        <template v-else>
          <div
            is="environment-item"
            v-for="children in model.children"
            :model="children"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"
            />

<<<<<<< HEAD

            <tr>
              <td
                colspan="6"
                class="text-center">
                <a
                  :href="folderUrl(model)"
                  class="btn btn-default">
                  Show all
                </a>
              </td>
            </tr>
          </template>
=======
          <div>
            <div class="text-center prepend-top-10">
              <a
                :href="folderUrl(model)"
                class="btn btn-default">
                Show all
              </a>
            </div>
          </div>
>>>>>>> ce/master
        </template>
      </template>
    </template>
  </div>
</template>
