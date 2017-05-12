<script>
/* global Flash */
import Visibility from 'visibilityjs';
import EnvironmentsService from '../services/environments_service';
import environmentTable from '../components/environments_table.vue';
import EnvironmentsStore from '../stores/environments_store';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import tablePagination from '../../vue_shared/components/table_pagination.vue';
import Poll from '../../lib/utils/poll';
import eventHub from '../event_hub';
import '../../lib/utils/common_utils';
import '../../vue_shared/vue_resource_interceptor';

export default {
  components: {
    environmentTable,
    tablePagination,
    loadingIcon,
  },

  data() {
    const environmentsData = document.querySelector('#environments-folder-list-view').dataset;
    const store = new EnvironmentsStore();
    const pathname = window.location.pathname;
    const endpoint = `${pathname}.json`;
    const folderName = pathname.substr(pathname.lastIndexOf('/') + 1);

    return {
      store,
      folderName,
      endpoint,
      state: store.state,
      visibility: 'available',
      isLoading: false,
      cssContainerClass: environmentsData.cssClass,
      canCreateDeployment: environmentsData.canCreateDeployment,
      canReadEnvironment: environmentsData.canReadEnvironment,
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

    /**
     * URL to link in the stopped tab.
     *
     * @return {String}
     */
    stoppedPath() {
      return `${window.location.pathname}?scope=stopped`;
    },

    /**
     * URL to link in the available tab.
     *
     * @return {String}
     */
    availablePath() {
      return window.location.pathname;
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

    eventHub.$on('postAction', this.postAction);
  },

  beforeDestroyed() {
    eventHub.$off('postAction');
  },

  methods: {
    /**
     * Will change the page number and update the URL.
     *
     * @param  {Number} pageNumber desired page to go to.
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

    successCallback(resp) {
      const response = {
        headers: resp.headers,
        body: resp.json(),
      };

      this.isLoading = false;

      this.store.storeAvailableCount(response.body.available_count);
      this.store.storeStoppedCount(response.body.stopped_count);
      this.store.storeEnvironments(response.body.environments);
      this.store.setPagination(response.headers);
    },

    errorCallback() {
      this.isLoading = false;
      // eslint-disable-next-line no-new
      new Flash('An error occurred while fetching the environments.');
    },

    postAction(endpoint) {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.service.postAction(endpoint)
          .then(() => this.fetchEnvironments())
          .catch(() => new Flash('An error occured while making the request.'));
      }
    },
  },
};
</script>
<template>
  <div :class="cssContainerClass">
    <div
      class="top-area"
      v-if="!isLoading">

      <h4 class="js-folder-name environments-folder-name">
        Environments / <b>{{folderName}}</b>
      </h4>

      <ul class="nav-links">
        <li :class="{ active: scope === null || scope === 'available' }">
          <a
            :href="availablePath"
            class="js-available-environments-folder-tab">
            Available
            <span class="badge js-available-environments-count">
              {{state.availableCounter}}
            </span>
          </a>
        </li>
        <li :class="{ active : scope === 'stopped' }">
          <a
            :href="stoppedPath"
            class="js-stopped-environments-folder-tab">
            Stopped
            <span class="badge js-stopped-environments-count">
              {{state.stoppedCounter}}
            </span>
          </a>
        </li>
      </ul>
    </div>

    <div class="environments-container">

      <loading-icon
        label="Loading environments"
        v-if="isLoading"
        size="3"
        />

      <div
        class="table-holder"
        v-if="!isLoading && state.environments.length > 0">

        <environment-table
          :environments="state.environments"
          :can-create-deployment="canCreateDeploymentParsed"
          :can-read-environment="canReadEnvironmentParsed"
          />

        <table-pagination
          v-if="state.paginationInformation && state.paginationInformation.totalPages > 1"
          :change="changePage"
          :pageInfo="state.paginationInformation"/>
      </div>
    </div>
  </div>
</template>
