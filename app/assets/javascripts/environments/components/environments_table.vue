<script>
/**
 * Render environments table.
 */
import EnvironmentTableRowComponent from './environment_item.vue';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    'environment-item': EnvironmentTableRowComponent,
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
  },

  methods: {
    folderUrl(model) {
      return `${window.location.pathname}/folders/${model.folderName}`;
    },
  },
};
</script>
<template>
  <div class="gl-responsive-table ci-table">
    <div class="gl-responsive-table-row table-row-header">
      <div class="table-section section-10 environments-name">
        Environment
      </div>
      <div class="table-section section-10 environments-deploy">
        Deployment
      </div>
      <div class="table-section section-15 environments-build">
        Job
      </div>
      <div class="table-section section-flex-full environments-commit">
        Commit
      </div>
      <div class="table-section section-10 environments-date">
        Updated
      </div>
      <div class="table-section section-flex-full environments-actions"></div>
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
          <div colspan="6">
            <loading-icon size="2" />
          </div>
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
            <div
              colspan="6"
              class="text-center">
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
