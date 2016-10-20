(() => {
  
  /**
   * Envrionment Item Component
   * 
   * Used in a hierarchical structure to show folders with children
   * in a table.
   * Based on [Tree View](https://vuejs.org/examples/tree-view.html) 
   * The template used in this Component is non recursive.
   * 
   * See this [issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/22539) 
   * for more information.
   */
  
  const Store = gl.environmentsList.EnvironmentsStore;

  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  gl.environmentsList.EnvironmentItem = Vue.extend({
    
    template: '#environment-item-template',

    props: {
      model: Object
    },

    data: function () {
      return {
        open: false
      };
    },
    
    computed: {
      
      /**
       * If an item has a `children` entry it means it is a folder.
       * Folder items have different behaviours - it is possible to toggle
       * them and show their children. 
       *
       * @returns {Number}  The length of the children array
       */
      isFolder: function () {
        return this.model.children && this.model.children.length
      }
    },

    methods: {

      /**
       * Toggles the visibility of a folders' children.
       */
      toggle: function () {
        if (this.isFolder) {
          this.open = !this.open;
        }
      }
    }
  })
})();
