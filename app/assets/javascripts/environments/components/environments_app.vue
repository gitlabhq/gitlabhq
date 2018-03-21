<script>
  import Flash from '../../flash';
  import { s__ } from '../../locale';
  import emptyState from './empty_state.vue';
  import eventHub from '../event_hub';
  import environmentsMixin from '../mixins/environments_mixin';
  import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';

  export default {
    components: {
      emptyState,
    },

    mixins: [
      CIPaginationMixin,
      environmentsMixin,
    ],

    props: {
      endpoint: {
        type: String,
        required: true,
      },
      canCreateEnvironment: {
        type: Boolean,
        required: true,
      },
      canCreateDeployment: {
        type: Boolean,
        required: true,
      },
      canReadEnvironment: {
        type: Boolean,
        required: true,
      },
      cssContainerClass: {
        type: String,
        required: true,
      },
      newEnvironmentPath: {
        type: String,
        required: true,
      },
      helpPagePath: {
        type: String,
        required: true,
      },
    },

    created() {
      eventHub.$on('toggleFolder', this.toggleFolder);
    },

    beforeDestroy() {
      eventHub.$off('toggleFolder');
    },

    methods: {
      toggleFolder(folder) {
        this.store.toggleFolder(folder);

        if (!folder.isOpen) {
          this.fetchChildEnvironments(folder, true);
        }
      },

      fetchChildEnvironments(folder, showLoader = false) {
        this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', showLoader);

        this.service.getFolderContent(folder.folder_path)
          .then(resp => resp.json())
          .then(response => this.store.setfolderContent(folder, response.environments))
          .then(() => this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', false))
          .catch(() => {
            Flash(s__('Environments|An error occurred while fetching the environments.'));
            this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', false);
          });
      },

      successCallback(resp) {
        this.saveData(resp);

        // We need to verify if any folder is open to also update it
        const openFolders = this.store.getOpenFolders();
        if (openFolders.length) {
          openFolders.forEach(folder => this.fetchChildEnvironments(folder));
        }
      },
    },
  };
</script>
<template>
  <div :class="cssContainerClass">
    <div class="top-area">
      <tabs
        :tabs="tabs"
        @onChangeTab="onChangeTab"
        scope="environments"
      />

      <div
        v-if="canCreateEnvironment && !isLoading"
        class="nav-controls"
      >
        <a
          :href="newEnvironmentPath"
          class="btn btn-create"
        >
          {{ s__("Environments|New environment") }}
        </a>
      </div>
    </div>

    <container
      :is-loading="isLoading"
      :environments="state.environments"
      :pagination="state.paginationInformation"
      :can-create-deployment="canCreateDeployment"
      :can-read-environment="canReadEnvironment"
      @onChangePage="onChangePage"
    >
      <empty-state
        slot="emptyState"
        v-if="!isLoading && state.environments.length === 0"
        :new-path="newEnvironmentPath"
        :help-path="helpPagePath"
        :can-create-environment="canCreateEnvironment"
      />
    </container>
  </div>
</template>
