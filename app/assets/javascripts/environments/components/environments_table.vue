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
          />

        <template v-if="model.isFolder && model.isOpen && model.children && model.children.length > 0">
          <tr v-if="isLoadingFolderContent">
            <td colspan="6">
              <loading-icon size="2" />
            </td>
          </tr>

          <template v-else>
            <tr
              is="environment-item"
              v-for="children in model.children"
              :model="children"
              :can-create-deployment="canCreateDeployment"
              :can-read-environment="canReadEnvironment"
              />

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
        </template>
      </template>
    </tbody>
  </table>
</template>
