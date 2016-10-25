//= require vue
//= require vue-resource
//= require_tree ./stores
//= require_tree ./services
//= require ./components/environment_item
//= require ../boards/vue_resource_interceptor

$(() => {
  
  const environmentsListApp = document.getElementById('environments-list-view');
  const Store = gl.environmentsList.EnvironmentsStore;
  
  window.gl = window.gl || {};
  
  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }
  
  const filterEnvironments = (environments = [], filter = "") => {
    return environments.filter((env) => {
      if (env.children) {
        return env.children.filter((child) =>  child.state === filter).length;
      } else {
        return env.state === filter;
      };
    });
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
        return filterEnvironments(this.state.environments, this.visibility);
      },

      countStopped () {
        return filterEnvironments(this.state.environments, 'stopped').length;
      },

      countAvailable () {
        return filterEnvironments(this.state.environments, 'available').length;
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
        
        console.log("HELLLLOOOOOOOOOOOOOO", resp.json())

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
        const paramSplited = param.split('=');
        acc[paramSplited[0]] = paramSplited[1];
        return acc;
      }, {})[param];
    }
  });
});
