//= require vue
//= require vue-resource
//= require_tree ../services/
//= require ./environment_item

/* globals Vue, EnvironmentsService */
/* eslint-disable no-param-reassign */

$(() => {
  window.gl = window.gl || {};

  const filterState = state => environment => environment.state === state && environment;

  // recursiveMap :: (Function, Array) -> Array
  const recursiveMap = (fn, arr) => arr.map((item) => {
    if (item.children) {
      const filteredChildren = recursiveMap(fn, item.children).filter(Boolean);
      if (filteredChildren.length) {
        item.children = filteredChildren;
        return item;
      }
    }
    return fn(item);
  }).filter(Boolean);

  window.gl.environmentsList.EnvironmentsComponent = Vue.component('environment-component', {
    props: {
      store: {
        type: Object,
        required: true,
        default: () => ({}),
      },
    },

    components: {
      'environment-item': window.gl.environmentsList.EnvironmentItem,
    },

    data() {
      const environmentsListApp = document.querySelector('#environments-list-view');

      return {
        state: this.store.state,
        endpoint: environmentsListApp.dataset.environmentsDataEndpoint,
        canCreateDeployment: environmentsListApp.dataset.canCreateDeployment,
        canReadEnvironment: environmentsListApp.dataset.canReadEnvironment,
        canCreateEnvironment: environmentsListApp.dataset.canCreateEnvironment,
        projectEnvironmentsPath: environmentsListApp.dataset.projectEnvironmentsPath,
        projectStoppedEnvironmentsPath: environmentsListApp.dataset.projectStoppedEnvironmentsPath,
        newEnvironmentPath: environmentsListApp.dataset.newEnvironmentPath,
        helpPagePath: environmentsListApp.dataset.helpPagePath,
        visibility: 'available',
        isLoading: false,
      };
    },

    computed: {
      filteredEnvironments() {
        return recursiveMap(filterState(this.visibility), this.state.environments);
      },

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

    created() {
      window.gl.environmentsService = new EnvironmentsService(this.endpoint);

      const scope = this.$options.getQueryParameter('scope');
      if (scope) {
        this.visibility = scope;
      }

      this.isLoading = true;

      return window.gl.environmentsService.all()
        .then(resp => resp.json())
        .then((json) => {
          this.store.storeEnvironments(json);
          this.isLoading = false;
        });
    },

    /**
     * Fetches all the environmnets and stores them.
     * Toggles loading property.
     */
    mounted() {

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
      if (string === 'true') {
        return true;
      }
      return false;
    },

    methods: {
      toggleRow(model) {
        return this.store.toggleFolder(model.name);
      },
    },

    template: `
      <div class="container-fluid container-limited">
        <div class="top-area">
          <ul v-if="!isLoading" class="nav-links">
            <li v-bind:class="{ 'active': scope === undefined}">
              <a :href="projectEnvironmentsPath">
                Available
                <span
                  class="badge js-available-environments-count"
                  v-html="state.availableCounter"></span>
              </a>
            </li>
            <li v-bind:class="{ 'active' : scope === 'stopped'}">
              <a :href="projectStoppedEnvironmentsPath">
                Stopped
                <span
                  class="badge js-stopped-environments-count"
                  v-html="state.stoppedCounter"></span>
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
            <i class="fa fa-spinner spin"></i>
          </div>

          <div
            class="blank-state blank-state-no-icon"
            v-if="!isLoading && state.environments.length === 0">
            <h2 class="blank-state-title">
              You don't have any environments right now.
            </h2>
            <p class="blank-state-text">
              Environments are places where code gets deployed, such as staging or production.

              <br />

              <a :href="helpPagePath">
                Read more about environments
              </a>
              <a
                v-if="canCreateEnvironmentParsed"
                :href="newEnvironmentPath"
                class="btn btn-create">
                New Environment
              </a>
            </p>
          </div>

          <div
            class="table-holder"
            v-if="!isLoading && state.environments.length > 0">
            <table class="table ci-table environments">
              <thead>
                <tr>
                  <th>Environment</th>
                  <th>Last deployment</th>
                  <th>Build</th>
                  <th>Commit</th>
                  <th></th>
                  <th class="hidden-xs"></th>
                </tr>
              </thead>
              <tbody>
                <template v-for="model in filteredEnvironments"
                  v-bind:model="model">

                  <tr
                    is="environment-item"
                    :model="model"
                    :toggleRow="toggleRow.bind(model)"
                    :can-create-deployment="canCreateDeploymentParsed"
                    :can-read-environment="canReadEnvironmentParsed"></tr>

                  <tr v-if="model.isOpen && model.children && model.children.length > 0"
                    is="environment-item"
                    v-for="children in model.children"
                    :model="children"
                    :toggleRow="toggleRow.bind(children)">
                    </tr>

                </template>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    `,
  });
});
