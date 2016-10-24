//= require vue
//= require vue-resource
//= require_tree ./stores
//= require_tree ./services
//= require ./components/environment_item

$(() => {
  
  const environmentsListApp = document.getElementById('environments-list-view');
  const Store = gl.environmentsList.EnvironmentsStore;
  
  window.gl = window.gl || {};
  
  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }
  
  const filters = {
    stopped (environments) {
      return environments.filter((env) => env.state === 'stopped')
    },
    available (environments) {
      return environments.filter((env) => env.state === 'available')
    }
  };
  
  gl.EnvironmentsListApp = new Vue({

    el: '#environments-list-view',
    
    components: {
      'item': gl.environmentsList.EnvironmentItem
    },

    data: {
      state: Store.state,
      endpoint: environmentsListApp.dataset.endpoint,
      loading: true,
      visibility: 'available'
    },
    
    computed: {
      filteredEnvironments () {
        return filters[this.visibility](this.state.environments);
      },
      
      countStopped () {
        return filters['stopped'](this.state.environments).length;
      },
      
      counAvailable () {
        return filters['available'](this.state.environments).length;
      }
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
      gl.environmentsService.all().then((resp) => {
        Store.storeEnvironments(resp.json());

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
    getQueryParameter(param) {
      return window.location.search.substring(1).split('&').reduce((acc, param) => {
        acc[param.split('=')[0]] = param.split('=')[1];
        return acc;
      }, {})[param];
    }

  });
});
