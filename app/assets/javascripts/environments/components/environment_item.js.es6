(() => {
  const Store = gl.environmentsList.EnvironmentsStore;

  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  gl.environmentsList.EnvironmentItem = Vue.extend({

    props: {
      model: Object
    },

    data: function () {
      return {
        open: false
      };
    },
    
    computed: {
      isFolder: function() {
        debugger;
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