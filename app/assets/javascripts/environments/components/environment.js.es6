/* eslint-disable no-param-reassign, no-new */
/* global Flash */

const Vue = require('vue');
Vue.use(require('vue-resource'));
const EnvironmentsService = require('../services/environments_service');
const EnvironmentItem = require('./environment_item');
const Store = require('../stores/environments_store');
require('../../vue_shared/components/table_pagination');

module.exports = Vue.component('environment-component', {

  components: {
    'environment-item': EnvironmentItem,
    'table-pagination': gl.VueGlPagination,
  },

  data() {
    const environmentsData = document.querySelector('#environments-list-view').dataset;
    const store = new Store();

    return {
      store,
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
      return this.$options.getQueryParameter('scope');
    },

    canReadEnvironmentParsed() {
      return this.$options.convertPermissionToBoolean(this.canReadEnvironment);
    },

    canCreateDeploymentParsed() {
      return this.$options.convertPermissionToBoolean(this.canCreateDeployment);
    },

    canCreateEnvironmentParsed() {
      return this.$options.convertPermissionToBoolean(this.canCreateEnvironment);
    },

  },

  /**
   * Fetches all the environments and stores them.
   * Toggles loading property.
   */
  created() {
    const scope = this.$options.getQueryParameter('scope') || this.visibility;
    const pageNumber = this.$options.getQueryParameter('page') || this.pageNumber;

    const endpoint = `${this.endpoint}?scope=${scope}&page=${pageNumber}`;

    const service = new EnvironmentsService(endpoint);

    this.isLoading = true;

    return service.all()
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

  /**
   * Transforms the url parameter into an object and
   * returns the one requested.
   *
   * @param  {String} param
   * @returns {String}       The value of the requested parameter.
   */
  getQueryParameter(parameter) {
    return window.location.search.substring(1).split('&').reduce((acc, param) => {
      const paramSplited = param.split('=');
      acc[paramSplited[0]] = paramSplited[1];
      return acc;
    }, {})[parameter];
  },

  /**
   * Converts permission provided as strings to booleans.
   * @param  {String} string
   * @returns {Boolean}
   */
  convertPermissionToBoolean(string) {
    return string === 'true';
  },

  methods: {
    toggleRow(model) {
      return this.store.toggleFolder(model.name);
    },

    /**
     * Will change the page number and update the URL.
     *
     * If no search params are present, we'll add param for page
     * If param for page is already present, we'll update it
     * If there are params but none for page, we'll add it at the end.
     *
     * @param  {Number} pageNumber desired page to go to.
     */
    changePage(pageNumber) {
      let param;
      if (window.location.search.length === 0) {
        param = `?page=${pageNumber}`;
      }

      if (window.location.search.indexOf('page') !== -1) {
        param = window.location.search.replace(/page=\d/g, `page=${pageNumber}`);
      }

      if (window.location.search.length &&
        window.location.search.indexOf('page') === -1) {
        param = `${window.location.search}&page=${pageNumber}`;
      }

      gl.utils.visitUrl(param);
      return param;
    },
  },

  template: `
    <div :class="cssContainerClass">
      <div class="top-area">
        <ul v-if="!isLoading" class="nav-links">
          <li v-bind:class="{ 'active': scope === undefined || scope === 'available' }">
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
          <table class="table ci-table environments">
            <thead>
              <tr>
                <th class="environments-name">Environment</th>
                <th class="environments-deploy">Last deployment</th>
                <th class="environments-build">Job</th>
                <th class="environments-commit">Commit</th>
                <th class="environments-date">Updated</th>
                <th class="hidden-xs environments-actions"></th>
              </tr>
            </thead>
            <tbody>
              <template v-for="model in state.environments"
                v-bind:model="model">
                <tr is="environment-item"
                  :model="model"
                  :can-create-deployment="canCreateDeploymentParsed"
                  :can-read-environment="canReadEnvironmentParsed"
                  :play-icon-svg="playIconSvg"
                  :terminal-icon-svg="terminalIconSvg"
                  :commit-icon-svg="commitIconSvg"></tr>
              </template>
            </tbody>
          </table>

          <table-pagination v-if="state.paginationInformation && state.paginationInformation.totalPages > 1"
            :change="changePage"
            :pageInfo="state.paginationInformation">
          </table-pagination>
        </div>
      </div>
    </div>
  `,
});
