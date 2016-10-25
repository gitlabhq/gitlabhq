(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.EnvironmentsStore = {
    state: {},

    create () {
      this.state.environments = [];
      this.state.stoppedCounter = 0;
      this.state.availableCounter = 0;
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

        if (environment.last_deployment) {

          //humanizes actions names if there are any actions
          if (environment.last_deployment.manual_actions) {
            environment.last_deployment.manual_actions = environment.last_deployment.manual_actions.map((action) => Object.assign({}, action, {name: gl.text.humanize(action.name)}));
          }
          
          //transforms created date for deployment in a human readable format
          if (environment.last_deployment.created_at) {
            // TODO - how to do this without jquery
          }
        }
        
        if (environment.environment_type !== null) {
          const occurs = acc.find((element, index, array) => {
            return element.children && element.name === environment.environment_type;
          });

          environment["vue-isChildren"] = true;

          if (occurs !== undefined) {
            acc[acc.indexOf(occurs)].children.push(environment);
            acc[acc.indexOf(occurs)].children.sort(this.sortByName)
          } else {
            acc.push({
              name: environment.environment_type,
              children: [
                Object.assign(environment)
              ]
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
     * Given an array of environments, returns the number of environments 
     * that have the given state.
     *
     * @param  {Array} environments 
     * @param  {String} state
     * @returns {Number}
     */
    countByState(environments, state) {
      return environments.filter((env) => env.state === state).length;
    },

    /**
     * Sorts the two objects provided by their name.
     *
     * @param  {Object} a
     * @param  {Object} b
     * @returns {Number}
     */
    sortByName (a, b) {
      const nameA = a.name.toUpperCase();
      const nameB = b.name.toUpperCase();

      if (nameA < nameB) {
        return -1;
      }

      if (nameA > nameB) {
        return 1;
      }

      return 0;
    }
  }
})();
