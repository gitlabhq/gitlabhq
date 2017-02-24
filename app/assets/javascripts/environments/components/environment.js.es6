/* eslint-disable no-param-reassign, no-new */
/* global Flash */

const Vue = window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
const EnvironmentsService = require('~/environments/services/environments_service');
const EnvironmentTable = require('./environments_table');
const EnvironmentsStore = require('~/environments/stores/environments_store');
require('~/vue_shared/components/table_pagination');
require('~/lib/utils/common_utils');
require('~/vue_shared/vue_resource_interceptor');

module.exports = Vue.component('environment-component', {

  components: {
    'environment-table': EnvironmentTable,
    'table-pagination': gl.VueGlPagination,
  },

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
      commitIconSvg: environmentsData.commitIconSvg,
      playIconSvg: environmentsData.playIconSvg,
      terminalIconSvg: environmentsData.terminalIconSvg,

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
    const pageNumber = gl.utils.getParameterByName('page') || this.pageNumber;

    const endpoint = `${this.endpoint}?scope=${scope}&page=${pageNumber}`;

    this.service = new EnvironmentsService(endpoint);

    this.isLoading = true;

    return this.service.get()
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
        new Flash('An error occurred while fetching the environments.', 'alert');
      });
  },

  methods: {

    /**
     * Toggles the visibility of the deploy boards of the clicked environment.
     *
     * @param  {Object} model
     * @return {Object}
     */
    toggleDeployBoard(model) {
      return this.store.toggleDeployBoard(model.id);
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
  },

  template: `
    <div :class="cssContainerClass">
      <div class="top-area">
        <ul v-if="!isLoading" class="nav-links">
          <li v-bind:class="{ 'active': scope === null || scope === 'available' }">
            <a :href="projectEnvironmentsPath">
              Available
              <span class="badge js-available-environments-count">
                {{state.availableCounter}}
              </span>
            </a>
          </li>
          <li v-bind:class="{ 'active' : scope === 'stopped' }">
            <a :href="projectStoppedEnvironmentsPath">
              Stopped
              <span class="badge js-stopped-environments-count">
                {{state.stoppedCounter}}
              </span>
            </a>
          </li>
        </ul>
        <div v-if="canCreateEnvironmentParsed && !isLoading" class="nav-controls">
          <a :href="newEnvironmentPath" class="btn btn-create">
            New environment
          </a>
        </div>
      </div>

      <div class="environments-container">
        <div class="environments-list-loading text-center" v-if="isLoading">
          <i class="fa fa-spinner fa-spin"></i>
        </div>

        <div class="blank-state blank-state-no-icon"
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

          <a v-if="canCreateEnvironmentParsed"
            :href="newEnvironmentPath"
            class="btn btn-create js-new-environment-button">
            New Environment
          </a>
        </div>

        <div class="table-holder"
          v-if="!isLoading && state.environments.length > 0">

          <environment-table
            :environments="state.environments"
            :can-create-deployment="canCreateDeploymentParsed"
            :can-read-environment="canReadEnvironmentParsed"
            :play-icon-svg="playIconSvg"
            :terminal-icon-svg="terminalIconSvg"
            :commit-icon-svg="commitIconSvg"
            :toggleDeployBoard="toggleDeployBoard"
            :store="store"
            :service="service">
          </environment-table>

          <table-pagination v-if="shouldRenderPagination"
            :change="changePage"
            :pageInfo="state.paginationInformation">
          </table-pagination>
        </div>
      </div>
    </div>
  `,
});
