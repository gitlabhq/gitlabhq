/* eslint-disable no-param-reassign */
(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.EnvironmentsStore = {
    state: {},

    create() {
      this.state.environments = [];
      this.state.stoppedCounter = 0;
      this.state.availableCounter = 0;
      this.state.filteredEnvironments = [];

      return this;
    },

    /**
     *
     * Stores the received environments.
     *
     * Each environment has the following schema
     * { name: String, size: Number, latest: Object }
     *
     * If the `size` is bigger than 1, it means it should be rendered as a folder.
     * In those cases we add `isFolder` key in order to render it properly.
     *
     * @param  {Array} environments
     * @returns {Array}
     */
    storeEnvironments(environments = []) {
      const filteredEnvironments = environments.map((env) => {
        if (env.size > 1) {
          return Object.assign({}, env, { isFolder: true });
        }

        return env;
      });

      this.state.environments = filteredEnvironments;

      return filteredEnvironments;
    },

    storeCounts() {
      //TODO
    },

  };
})();
