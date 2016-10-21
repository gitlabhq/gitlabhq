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
    storeEnvironments(environments) {
      const environmentsTree = environments.reduce((acc, environment) => {
        const data = Object.assign({}, environment);
        
        if (data.last_deployment) {

          //humanizes actions names if there are any actions
          if (data.last_deployment.manual_actions) {
            data.last_deployment.manual_actions = data.last_deployment.manual_actions.map((action) => Object.assign({}, action, {name: gl.text.humanize(action.name)}));
          }
          
          //transforms created date for deployment in a human readable format
          if (data.last_deployment.created_at) {
            // TODO - how to do this without jquery
          }
        }
        
        if (environment.environment_type !== null) {
          const occurs = acc.find((element, index, array) => {
            return element.name === environment.environment_type;
          });
          
          data["vue-isChildren"] = true;

          if (occurs !== undefined) {
            acc[acc.indexOf(occurs)].children.push(data);
            acc[acc.indexOf(occurs)].children.sort();
          } else {
            acc.push({
              name: environment.environment_type,
              children: [
                Object.assign(data)
              ]
            });
          }
        } else {
          acc.push(data);
        }

        return acc;
      }, []).sort();
    
      this.state.environments = environmentsTree;
      
      return environmentsTree;
    }
  }
})();
