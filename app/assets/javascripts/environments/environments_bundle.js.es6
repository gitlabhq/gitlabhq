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
  
  gl.EnvironmentsListApp = new Vue({

    el: '#environments-list-view',
    
    components: {
      'environment-item': gl.environmentsList.EnvironmentItem
    },

    data: {
      state: Store.state,
      endpoint: environmentsListApp.dataset.endpoint,
      loading: true
    },
    
    init: Store.create.bind(Store),
    
    created() {
      gl.environmentsService = new EnvironmentsService(this.endpoint);
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
    }
  });
});
