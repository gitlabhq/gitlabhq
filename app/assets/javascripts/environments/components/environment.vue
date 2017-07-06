<script>
/* global Flash */
import Visibility from 'visibilityjs';
import EnvironmentsService from '../services/environments_service';
import environmentTable from './environments_table.vue';
import EnvironmentsStore from '../stores/environments_store';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import tablePagination from '../../vue_shared/components/table_pagination.vue';
import '../../lib/utils/common_utils';
import eventHub from '../event_hub';
import Poll from '../../lib/utils/poll';
import environmentsMixin from '../mixins/environments_mixin';

export default {

  components: {
    environmentTable,
    tablePagination,
    loadingIcon,
  },

  mixins: [
    environmentsMixin,
  ],

  data() {
    const environmentsData = document.querySelector('#environments-list-view').dataset;
    const store = new EnvironmentsStore();

    return {
      store,
      service: {},
      state: store.state,
      visibility: 'available',
      isLoading: false,
      cssContainerClass: environmentsData.cssClass,
      endpoint: environmentsData.environmentsDataEndpoint,
      canCreateDeployment: environmentsData.canCreateDeployment,
      canReadEnvironment: environmentsData.canReadEnvironment,
      canCreateEnvironment: environmentsData.canCreateEnvironment,
      projectEnvironmentsPath: environmentsData.projectEnvironmentsPath,
      projectStoppedEnvironmentsPath: environmentsData.projectStoppedEnvironmentsPath,
      newEnvironmentPath: environmentsData.newEnvironmentPath,
      helpPagePath: environmentsData.helpPagePath,
      isMakingRequest: false,

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

    /**
     * Pagination should only be rendered when we have information about it and when the
     * number of total pages is bigger than 1.
     *
     * @return {Boolean}
     */
    shouldRenderPagination() {
      return this.state.paginationInformation && this.state.paginationInformation.totalPages > 1;
    },
  },

  /**
   * Fetches all the environments and stores them.
   * Toggles loading property.
   */
  created() {
    const scope = gl.utils.getParameterByName('scope') || this.visibility;
    const page = gl.utils.getParameterByName('page') || this.pageNumber;

    this.service = new EnvironmentsService(this.endpoint);

    const poll = new Poll({
      resource: this.service,
      method: 'get',
      data: { scope, page },
      successCallback: this.successCallback,
      errorCallback: this.errorCallback,
      notificationCallback: (isMakingRequest) => {
        this.isMakingRequest = isMakingRequest;
      },
    });

    if (!Visibility.hidden()) {
      this.isLoading = true;
      poll.makeRequest();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        poll.restart();
      } else {
        poll.stop();
      }
    });

    eventHub.$on('toggleFolder', this.toggleFolder);
    eventHub.$on('postAction', this.postAction);
    eventHub.$on('toggleDeployBoard', this.toggleDeployBoard);
  },

  beforeDestroy() {
    eventHub.$off('toggleFolder');
    eventHub.$off('postAction');
    eventHub.$off('toggleDeployBoard');
  },

  methods: {

    /**
     * Toggles the visibility of the deploy boards of the clicked environment.
     *
     * @param  {Object} model
     * @return {Object}
     */
    toggleDeployBoard(model) {
      this.store.toggleDeployBoard(model.id);

      if (!model.isDeployboardVisible) {
        this.fetchDeployBoard(model, true);
      }
    },

    toggleFolder(folder, folderUrl) {
      this.store.toggleFolder(folder);

      if (!folder.isOpen) {
        this.fetchChildEnvironments(folder, folderUrl, true);
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
      const page = gl.utils.getParameterByName('page') || this.pageNumber;

      this.isLoading = true;

      return this.service.get({ scope, page })
        .then(this.successCallback)
        .catch(this.errorCallback);
    },

    fetchChildEnvironments(folder, folderUrl, showLoader = false) {
      this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', showLoader);

      this.service.getFolderContent(folderUrl)
        .then(resp => resp.json())
        .then(response => this.store.setfolderContent(folder, response.environments))
        .then(() => this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', false))
        .catch(() => {
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the environments.');
          this.store.updateEnvironmentProp(folder, 'isLoadingFolderContent', false);
        });
    },

    postAction(endpoint) {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.service.postAction(endpoint)
          .then(() => this.fetchEnvironments())
          .catch(() => new Flash('An error occured while making the request.'));
      }
    },

    successCallback(resp) {
      this.saveData(resp);

      // We need to verify if any folder is open to also update it
      const openFolders = this.store.getOpenFolders();
      if (openFolders.length) {
        openFolders.forEach((folder) => {
          // TODO - Move this to the backend
          const folderUrl = `${window.location.pathname}/folders/${folder.folderName}`;

          return this.fetchChildEnvironments(folder, folderUrl);
        });
      }

      const openDeployBoards = this.store.getOpenDeployBoards();
      if (openDeployBoards.length) {
        openDeployBoards.forEach(env => this.fetchDeployBoard(env));
      }
    },

    errorCallback() {
      this.isLoading = false;
      // eslint-disable-next-line no-new
      new Flash('An error occurred while fetching the environments.');
    },

    fetchDeployBoard(environment, showLoader = false) {
      this.store.updateEnvironmentProp(environment, 'isLoadingDeployBoard', showLoader);

      this.service.getDeployBoard(environment.rollout_status_path)
        .then(resp => resp.json())
        .then((data) => {
          this.store.storeDeployBoard(environment.id, data);
          this.store.updateEnvironmentProp(environment, 'isLoadingDeployBoard', false);
        })
        .catch(() => {
          this.store.updateEnvironmentProp(environment, 'isLoadingDeployBoard', false);
          this.store.updateEnvironmentProp(environment, 'hasErrorDeployBoard', true);
          // eslint-disable-next-line no-new
          new Flash('An error occurred while fetching the deploy board.');
        });
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
        <li :class="{ 'active' : scope === 'stopped' }">
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

    <div class="environments-container">
      <loading-icon
        label="Loading environments"
        size="3"
        v-if="isLoading"
        />

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
          New environment
        </a>
      </div>

      <div
        class="table-holder"
        v-if="!isLoading && state.environments.length > 0">

        <environment-table
          :environments="state.environments"
          :can-create-deployment="canCreateDeploymentParsed"
          :can-read-environment="canReadEnvironmentParsed"
          />
      </div>

      <table-pagination v-if="state.paginationInformation && state.paginationInformation.totalPages > 1"
        :change="changePage"
        :pageInfo="state.paginationInformation" />
    </div>
  </div>
</template>
