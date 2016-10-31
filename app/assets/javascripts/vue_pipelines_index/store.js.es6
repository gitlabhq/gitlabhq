/* global gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.PipelineStore = class {
    fetchDataLoop(Vue) {
      const goFetch = vue =>
        this.$http.get(`/api/v3/projects/${this.scope}/pipelines`)
          .then((response) => {
            vue.set(this, 'pipelines', JSON.parse(response.body));
          }, () => {
            console.error('API Error for Pipelines');
          });

      setInterval(() => {
        console.log('DID IT');
        goFetch(Vue);
      }, 30000);
    }

    fetchCommits(vue) {
      const goFetch = vueSet =>
        this.$http.get(`/api/v3/projects/${this.scope}/pipelines`)
          .then((response) => {
            vueSet.set(this, 'pipelines', JSON.parse(response.body));
          }, () => {
            console.error('API Error for Pipelines');
          });

      this.$http.get(`/api/v3/projects/${this.scope}/repository/commits`)
        .then((response) => {
          vue.set(this, 'commits', JSON.parse(response.body));
        }, () => {
          console.error('API Error for Pipelines');
        })
        .then(() => goFetch(vue));
    }
  };
})(window.gl || (window.gl = {}));
