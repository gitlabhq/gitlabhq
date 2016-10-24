(() => {
  
  /**
   * Envrionment Item Component
   * 
   * Used in a hierarchical structure to show folders with children
   * in a table.
   * Recursive component based on [Tree View](https://vuejs.org/examples/tree-view.html) 
   * 
   * See this [issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/22539) 
   * for more information.
   */
  
  const Store = gl.environmentsList.EnvironmentsStore;

  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  gl.environmentsList.EnvironmentItem = Vue.component('environment-item', {
    
    template: '#environment-item-template',

    props: {
      model: Object
    },

    data () {
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
       * @returns {Boolean}
       */
      isFolder () {
        return this.model.children && this.model.children.length ? true : false;
      },
      
      /**
       * If an item is inside a folder structure will return true.
       * Used for css purposes.
       *
       * @returns {Boolean|undefined}
       */
      isChildren () {
        return this.model['vue-isChildren'];
      },
      
      
      /**
       * Counts the number of environments in each folder.
       * Used to show a badge with the counter.
       *
       * @returns {Boolean}  The number of environments for the current folder
       */
      childrenCounter () {
        return this.model.children && this.model.children.length;
      }
    },

    methods: {

      /**
       * Toggles the visibility of a folders' children.
       */
      toggle () {
        if (this.isFolder) {
          this.open = !this.open;
        }
      }
    }
  })
})();
