(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};
  
  gl.environmentsList.EnvironmentsStore = {
    
    create () {

    },
    
    /**
     * Stores the received environmnets.
     * 
     * @param  {Array} environments List of environments
     * @return {type}
     */     
    addEnvironments(environments) {
      console.log(environments);
    } 
  }
})();