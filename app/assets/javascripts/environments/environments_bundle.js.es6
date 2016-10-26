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
  
  
  const filterState = (state) => (environment) => environment.state === state && environment;
  
  // recursiveMap :: (Function, Array) -> Array 
  const recursiveMap = (fn, arr) => {
    return arr.map((item) => {
      if (!item.children) { return fn(item); }
      
      const filteredChildren = recursiveMap(fn, item.children).filter(Boolean);
      if (filteredChildren.length) {
        item.children = filteredChildren;
        return item;
      }
      
    }).filter(Boolean);
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
        return recursiveMap(filterState(this.visibility), this.state.environments);
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
        const paramSplited = param.split('=');
        acc[paramSplited[0]] = paramSplited[1];
        return acc;
      }, {})[param];
    }
  });
});
