//= require vue
//= require vue-resource
//= require_tree ./stores
//= require_tree ./services


$(() => {
  
  const $environmentsListApp = document.getElementById('environments-list-view');
  const Store = gl.environmentsList.EnvironmentsStore;
  
  window.gl = window.gl || {};
  
  if (gl.EnvironmentsListApp) {
    gl.EnvironmentsListApp.$destroy(true);
  }
  
  gl.EnvironmentsListApp = new Vue({

    el: $environmentsListApp,
    
    components: {
      'tree-view': gl.environmentsList.TreeView
    },

    data: {
      endpoint: $environmentsListApp.dataset.endpoint,
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
        Store.addEnvironments(resp.json());

        this.loading = false;
      });
    }
  });
});