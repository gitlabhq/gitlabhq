((w) => {
  w.ButtonMixins = {
    computed: {
      namespace: function () {
        return `${this.namespacePath}/${this.projectPath}`;
      }
    }
  };
})(window);
