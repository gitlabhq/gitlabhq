(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  gl.environmentsList.EnvironmentsStore = {
    state: {},
    
    create () {
      this.state.environments = [];
    },
    
    /**
     * In order to display a tree view we need to modify the received 
     * data in to a tree structure based on `environment_type` 
     * sorted alphabetically.
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
     *        { name: "environment", environment_type: "review"},
     *        { name: "environment_2", environment_type: "review"}
     *      ]
     *   },
     *  {name: "environment_1", environment_type: null}
     * ]
     * 
     * 
     * @param  {Array} environments List of environments.
     * @returns {Array} Tree structured array with the received environments.
     */
    storeEnvironments(environments) {
      const environmentsTree = environments.reduce((acc, environment) => {
        if (environment.environment_type !== null) {
          const occurs = acc.find((element, index, array) => {
            return element.name === environment.environment_type;
          });

          if (occurs !== undefined) {
            acc[acc.indexOf(occurs)].children.push(environment);
            acc[acc.indexOf(occurs)].children.sort();
          } else {
            acc.push({
              name: environment.environment_type,
              children: [environment]
            });
          }
        } else {
          acc.push(environment);
        }

        return acc;
      }, []).sort();
    
      this.state.environments = environmentsTree;
      
      return environmentsTree;
    }
  }
})();
