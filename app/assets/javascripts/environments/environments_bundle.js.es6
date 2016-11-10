//= require vue
//= require vue-resource
//= require_tree ./stores
//= require_tree ./services
//= require ./components/environment_item
//= require ./vue_resource_interceptor
/* globals Vue, EnvironmentsService */
/* eslint-disable no-param-reassign */

$(() => {
  const environmentsListApp = document.getElementById('environments-list-view');
  const Store = gl.environmentsList.EnvironmentsStore;

  window.gl = window.gl || {};

  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }

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

  gl.EnvironmentsListApp = new Vue({

    el: '#environments-list-view',

    components: {
      item: gl.environmentsList.EnvironmentItem,
    },

    data: {
      state: Store.state,
      endpoint: environmentsListApp.dataset.environmentsDataEndpoint,
      canCreateDeployment: environmentsListApp.dataset.canCreateDeployment,
      canReadEnvironment: environmentsListApp.dataset.canReadEnvironment,
      canCreateEnvironment: environmentsListApp.dataset.canCreateEnvironment,
      projectEnvironmentsPath: environmentsListApp.dataset.projectEnvironmentsPath,
      projectClosedEnvironmentsPath: environmentsListApp.dataset.projectClosedEnvironmentsPath,
      newEnvironmentPath: environmentsListApp.dataset.newEnvironmentPath,
      helpPagePath: environmentsListApp.dataset.helpPagePath,
      loading: true,
      visibility: 'available',
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
    },

    init: Store.create.bind(Store),

    created() {
      gl.environmentsService = new EnvironmentsService(this.endpoint);

      const scope = this.$options.getQueryParameter('scope');
      if (scope) {
        this.visibility = scope;
      }
    },

    /**
     * Fetches all the environmnets and stores them.
     * Toggles loading property.
     */
    ready() {
      gl.environmentsService.all().then(resp => resp.json()).then((json) => {
        Store.storeEnvironments(json);
        this.loading = false;
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
      if (string === 'true') {
        return true;
      }

      return false;
    },

    template: `
      <div>
        <div class="top-area">
          <ul v-if="!isLoading" class="nav-links">
            <li v-bind:class="{ 'active': scope === undefined}">
              <a :href="projectEnvironmentsPath">
                Available
                <span class="badge js-available-environments-count">
                  {{state.availableCounter}}
                </span>
              </a>
            </li>
            <li v-bind:class="{ 'active': scope === 'stopped'}">
              <a :href="projectClosedEnvironmentsPath">
                Stopped
                <span class="badge js-stopped-environments-count">
                  {{state.stoppedCounter}}
                </span>
              </a>
            </li>
          </ul>
          <div v-if="canCreateEnvironment && !loading" class="nav-controls">
            <a :href="newEnvironmentPath" class="btn btn-create">
              New envrionment
            </a>
          </div>
        </div>
        
        <div class="environments-container">
          <div class="environments-list-loading text-center" v-if="loading">
            <i class="fa fa-spinner spin"></i>
          </div>
        
          <div class="blank-state blank-state-no-icon" v-if="!loading && state.environments.length === 0">
            <h2 class="blank-state-title">
              You don't have any environments right now.
            </h2>
            <p class="blank-state-text">
              Environments are places where code gets deployed, such as staging or production.
              
              <br />
              
              <a :href="helpPagePath">
                Read more about environments
              </a>
              <a v-if="canCreateEnvironment" :href="newEnvironmentPath" class="btn btn-create">
                New Environment
              </a>
            </p>
          </div>
          
          <div class="table-holder" v-if="!loading && state.environments.length > 0">
            <table class="table ci-table environments">
              <thead>
                <th>Environment</th>
                <th>Last deployment</th>
                <th>Build</th>
                <th>Commit</th>
                <th></th>
                <th class="hidden-xs"></th>
              </thead>
              <tbody>
                <tr is="environment-item"
                  v-for="model in filteredEnvironments"
                  :model="model"
                  :can-create-deployment="canCreateDeploymentParsed"
                  :can-read-environment="canReadEnvironmentParsed">
              </tbody>
            </table>
          </div>
        </div>
      </div>  
    `,
  });
});
