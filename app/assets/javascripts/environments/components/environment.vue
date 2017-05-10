<script>
/* global Flash */
import EnvironmentsService from '../services/environments_service';
import environmentTable from './environments_table.vue';
import EnvironmentsStore from '../stores/environments_store';
import tablePagination from '../../vue_shared/components/table_pagination.vue';
import '../../lib/utils/common_utils';
import eventHub from '../event_hub';

export default {

  components: {
    environmentTable,
    tablePagination,
  },

  data() {
    const environmentsData = document.querySelector('#environments-list-view').dataset;
    const store = new EnvironmentsStore();

    return {
      store,
      state: store.state,
      visibility: 'available',
      isLoading: false,
      isLoadingFolderContent: false,
      cssContainerClass: environmentsData.cssClass,
      endpoint: environmentsData.environmentsDataEndpoint,
      canCreateDeployment: environmentsData.canCreateDeployment,
      canReadEnvironment: environmentsData.canReadEnvironment,
      canCreateEnvironment: environmentsData.canCreateEnvironment,
      projectEnvironmentsPath: environmentsData.projectEnvironmentsPath,
      projectStoppedEnvironmentsPath: environmentsData.projectStoppedEnvironmentsPath,
      newEnvironmentPath: environmentsData.newEnvironmentPath,
      helpPagePath: environmentsData.helpPagePath,

      // Pagination Properties,
      paginationInformation: {},
      pageNumber: 1,
    };
  },

  computed: {
    scope() {
      return gl.utils.getParameterByName('scope');
    },

    canReadEnvironmentParsed() {
      return gl.utils.convertPermissionToBoolean(this.canReadEnvironment);
    },

    canCreateDeploymentParsed() {
      return gl.utils.convertPermissionToBoolean(this.canCreateDeployment);
    },

    canCreateEnvironmentParsed() {
      return gl.utils.convertPermissionToBoolean(this.canCreateEnvironment);
    },
  },

  /**
   * Fetches all the environments and stores them.
   * Toggles loading property.
   */
  created() {
    this.service = new EnvironmentsService(this.endpoint);

    this.fetchEnvironments();

    eventHub.$on('refreshEnvironments', this.fetchEnvironments);
    eventHub.$on('toggleFolder', this.toggleFolder);
    eventHub.$on('postAction', this.postAction);
  },

  beforeDestroyed() {
    eventHub.$off('refreshEnvironments');
    eventHub.$off('toggleFolder');
    eventHub.$off('postAction');
  },

  methods: {
    toggleFolder(folder, folderUrl) {
      this.store.toggleFolder(folder);

      if (!folder.isOpen) {
        this.fetchChildEnvironments(folder, folderUrl);
      }
    },

    /**
     * Will change the page number and update the URL.
     *
     * @param  {Number} pageNumber desired page to go to.
     * @return {String}
     */
    changePage(pageNumber) {
      const param = gl.utils.setParamInURL('page', pageNumber);

      gl.utils.visitUrl(param);
      return param;
    },

    fetchEnvironments() {
      const scope = gl.utils.getParameterByName('scope') || this.visibility;
      const pageNumber = gl.utils.getParameterByName('page') || this.pageNumber;

      this.isLoading = true;

      return this.service.get(scope, pageNumber)
        .then(resp => ({
          headers: resp.headers,
          body: resp.json(),
        }))
        .then((response) => {
          this.store.storeAvailableCount(response.body.available_count);
          this.store.storeStoppedCount(response.body.stopped_count);
          this.store.storeEnvironments(response.body.environments);
          this.store.setPagination(response.headers);
        })
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          this.isLoading = false;
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the environments.');
        });
    },

    fetchChildEnvironments(folder, folderUrl) {
      this.isLoadingFolderContent = true;

      this.service.getFolderContent(folderUrl)
        .then(resp => resp.json())
        .then((response) => {
          this.store.setfolderContent(folder, response.environments);
          this.isLoadingFolderContent = false;
        })
        .catch(() => {
          this.isLoadingFolderContent = false;
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the environments.');
        });
    },

    postAction(endpoint) {
      this.service.postAction(endpoint)
        .then(() => this.fetchEnvironments())
        .catch(() => new Flash('An error occured while making the request.'));
    },
  },
};
</script>
<template>
  <div :class="cssContainerClass">
    <div class="top-area">
      <ul
        v-if="!isLoading"
        class="nav-links">
        <li :class="{ active: scope === null || scope === 'available' }">
          <a :href="projectEnvironmentsPath">
            Available
            <span class="badge js-available-environments-count">
              {{state.availableCounter}}
            </span>
          </a>
        </li>
        <li :class="{ active : scope === 'stopped' }">
          <a :href="projectStoppedEnvironmentsPath">
            Stopped
            <span class="badge js-stopped-environments-count">
              {{state.stoppedCounter}}
            </span>
          </a>
        </li>
      </ul>
      <div
        v-if="canCreateEnvironmentParsed && !isLoading"
        class="nav-controls">
        <a
          :href="newEnvironmentPath"
          class="btn btn-create">
          New environment
        </a>
      </div>
    </div>

    <div class="content-list environments-container">
      <div
          class="environments-list-loading text-center"
          v-if="isLoading">

        <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true" />
      </div>

      <div
        class="blank-state blank-state-no-icon"
        v-if="!isLoading && state.environments.length === 0">
        <h2 class="blank-state-title js-blank-state-title">
          You don't have any environments right now.
        </h2>
        <p class="blank-state-text">
          Environments are places where code gets deployed, such as staging or production.
          <br />
          <a :href="helpPagePath">
            Read more about environments
          </a>
        </p>

        <a
          v-if="canCreateEnvironmentParsed"
          :href="newEnvironmentPath"
          class="btn btn-create js-new-environment-button">
          New Environment
        </a>
      </div>

      <div
        class="table-holder"
        v-if="!isLoading && state.environments.length > 0">

        <environment-table
          :environments="state.environments"
          :can-create-deployment="canCreateDeploymentParsed"
          :can-read-environment="canReadEnvironmentParsed"
          :is-loading-folder-content="isLoadingFolderContent" />
      </div>

      <table-pagination
        v-if="state.paginationInformation && state.paginationInformation.totalPages > 1"
        :change="changePage"
        :pageInfo="state.paginationInformation" />
    </div>
  </div>
</template>
