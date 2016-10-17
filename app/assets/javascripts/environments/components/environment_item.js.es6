(() => {
  const Store = gl.environmentsList.EnvironmentsStore;

  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  debugger;
  
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
      isFolder: function () {
        return this.model.children && this.model.children.length
      }
    },

    methods: {
      toggle: function () {
        if (this.isFolder) {
          this.open = !this.open;
        }
      }
    }
  })
})();