/* eslint-disable no-param-reassign, no-new */
/* global Flash */

const Vue = require('vue');
Vue.use(require('vue-resource'));
const EnvironmentsService = require('../services/environments_service');
const EnvironmentTable = require('../components/environments_table');
const Store = require('../stores/environments_store');
require('../../lib/utils/common_utils');

module.exports = Vue.component('environment-folder-view', {

  components: {
    'environment-table': EnvironmentTable,
    'table-pagination': gl.VueGlPagination,
  },

  data() {
    const environmentsData = document.querySelector('#environments-folder-list-view').dataset;
    const store = new Store();
    const endpoint = `${window.location.pathname}.json`;

    return {
      store,
      endpoint,
      state: store.state,
      visibility: 'available',
      isLoading: false,
      cssContainerClass: environmentsData.cssClass,
      canCreateDeployment: environmentsData.canCreateDeployment,
      canReadEnvironment: environmentsData.canReadEnvironment,

      // svgs
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
      return this.$options.convertPermissionToBoolean(this.canReadEnvironment);
    },

    canCreateDeploymentParsed() {
      return this.$options.convertPermissionToBoolean(this.canCreateDeployment);
    },

    stoppedPath() {
      return `${window.location.pathname}?scope=stopped`;
    },

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
    const pageNumber = gl.utils.getParameterByName('page') || this.pageNumber;

    const endpoint = `${this.endpoint}?scope=${scope}&page=${pageNumber}`;

    const service = new EnvironmentsService(endpoint);

    this.isLoading = true;

    return service.all()
      .then(resp => ({
        headers: resp.headers,
        body: resp.json(),
      }))
      .then((response) => {
        this.store.storeEnvironments(response.body.environments);
        this.store.storePagination(response.headers);
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

  methods: {
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

        <h3>FOLDER NAME</h3>

        <ul v-if="!isLoading" class="nav-links">
          <li v-bind:class="{ 'active': scope === undefined || scope === 'available' }">
            <a :href="availablePath">
              Available
              <span class="badge js-available-environments-count">
                {{state.availableCounter}}
              </span>
            </a>
          </li>
          <li v-bind:class="{ 'active' : scope === 'stopped' }">
            <a :href="stoppedPath">
              Stopped
              <span class="badge js-stopped-environments-count">
                {{state.stoppedCounter}}
              </span>
            </a>
          </li>
        </ul>
      </div>

      <div class="environments-container">
        <div class="environments-list-loading text-center" v-if="isLoading">
          <i class="fa fa-spinner fa-spin"></i>
        </div>

        <div class="table-holder"
          v-if="!isLoading && state.environments.length > 0">

          <environment-table
            :environments="state.environments"
            :can-create-deployment="canCreateDeploymentParsed"
            :can-read-environment="canReadEnvironmentParsed"
            :play-icon-svg="playIconSvg"
            :terminal-icon-svg="terminalIconSvg"
            :commit-icon-svg="commitIconSvg">
          </environment-table>

          <table-pagination v-if="state.paginationInformation && state.paginationInformation.totalPages > 1"
            :change="changePage"
            :pageInfo="state.paginationInformation">
          </table-pagination>
        </div>
      </div>
    </div>
  `,
});
