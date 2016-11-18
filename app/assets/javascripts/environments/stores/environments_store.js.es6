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

      return this;
    },

    /**
     * In order to display a tree view we need to modify the received
     * data in to a tree structure based on `environment_type`
     * sorted alphabetically.
     * In each children a `vue-` property will be added. This property will be
     * used to know if an item is a children mostly for css purposes. This is
     * needed because the children row is a fragment instance and therfore does
     * not accept non-prop attributes.
     *
     *
     * @example
     * it will transform this:
     * [
     *   { name: "environment", environment_type: "review" },
     *   { name: "environment_1", environment_type: null }
     *   { name: "environment_2, environment_type: "review" }
     * ]
     * into this:
     * [
     *   { name: "review", children:
     *      [
     *        { name: "environment", environment_type: "review", vue-isChildren: true},
     *        { name: "environment_2", environment_type: "review", vue-isChildren: true}
     *      ]
     *   },
     *  {name: "environment_1", environment_type: null}
     * ]
     *
     *
     * @param  {Array} environments List of environments.
     * @returns {Array} Tree structured array with the received environments.
     */
    storeEnvironments(environments = []) {
      this.state.stoppedCounter = this.countByState(environments, 'stopped');
      this.state.availableCounter = this.countByState(environments, 'available');

      const environmentsTree = environments.reduce((acc, environment) => {
        if (environment.environment_type !== null) {
          const occurs = acc.filter(element => element.children &&
             element.name === environment.environment_type);

          environment['vue-isChildren'] = true;

          if (occurs.length) {
            acc[acc.indexOf(occurs[0])].children.push(environment);
            acc[acc.indexOf(occurs[0])].children.sort(this.sortByName);
          } else {
            acc.push({
              name: environment.environment_type,
              children: [environment],
              isOpen: false,
              'vue-isChildren': environment['vue-isChildren'],
            });
          }
        } else {
          acc.push(environment);
        }

        return acc;
      }, []).sort(this.sortByName);

      this.state.environments = environmentsTree;

      return environmentsTree;
    },

    /**
     * Toggles folder open property given the environment type.
     *
     * @param  {String} envType
     * @return {Array}
     */
    toggleFolder(envType) {
      const environments = this.state.environments;

      const environmentsCopy = environments.map((env) => {
        if (env['vue-isChildren'] && env.name === envType) {
          env.isOpen = !env.isOpen;
        }

        return env;
      });

      this.state.environments = environmentsCopy;

      return environmentsCopy;
    },

    /**
     * Given an array of environments, returns the number of environments
     * that have the given state.
     *
     * @param  {Array} environments
     * @param  {String} state
     * @returns {Number}
     */
    countByState(environments, state) {
      return environments.filter(env => env.state === state).length;
    },

    /**
     * Sorts the two objects provided by their name.
     *
     * @param  {Object} a
     * @param  {Object} b
     * @returns {Number}
     */
    sortByName(a, b) {
      const nameA = a.name.toUpperCase();
      const nameB = b.name.toUpperCase();

      if (nameA < nameB) {
        return -1;
      }

      if (nameA > nameB) {
        return 1;
      }

      return 0;
    },
  };
})();
