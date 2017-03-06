/* eslint-disable no-new */

const Vue = window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
const EnvironmentsService = require('~/environments//services/environments_service');
const EnvironmentTable = require('~/environments/components/environments_table');
const EnvironmentsStore = require('~/environments//stores/environments_store');
const Flash = require('~/flash');
require('~/vue_shared/components/table_pagination');
require('~/lib/utils/common_utils');
require('~/vue_shared/vue_resource_interceptor');

module.exports = Vue.component('environment-folder-view', {

  components: {
    'environment-table': EnvironmentTable,
    'table-pagination': gl.VueGlPagination,
  },

  data() {
    const environmentsData = document.querySelector('#environments-folder-list-view').dataset;
    const store = new EnvironmentsStore();
    const pathname = window.location.pathname;
    const endpoint = `${pathname}.json`;
    const folderName = pathname.substr(pathname.lastIndexOf('/') + 1);

    return {
      store,
      service: {},
      folderName,
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
     */
    changePage(pageNumber) {
      const param = gl.utils.setParamInURL('page', pageNumber);

      gl.utils.visitUrl(param);
      return param;
    },
  },

  template: `
    <div :class="cssContainerClass">
      <div class="top-area" v-if="!isLoading">

        <h4 class="js-folder-name environments-folder-name">
          Environments / <b>{{folderName}}</b>
        </h4>

        <ul class="nav-links">
          <li v-bind:class="{ 'active': scope === null || scope === 'available' }">
            <a :href="availablePath" class="js-available-environments-folder-tab">
              Available
              <span class="badge js-available-environments-count">
                {{state.availableCounter}}
              </span>
            </a>
          </li>
          <li v-bind:class="{ 'active' : scope === 'stopped' }">
            <a :href="stoppedPath" class="js-stopped-environments-folder-tab">
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
            :commit-icon-svg="commitIconSvg"
            :toggleDeployBoard="toggleDeployBoard"
            :store="store"
            :service="service">
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
