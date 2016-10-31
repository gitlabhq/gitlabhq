/* global gl */
/* eslint-disable no-param-reassign */

((gl) => {
  const goFetch = (that, vue) =>
    that.$http.get(`/api/v3/projects/${that.scope}/pipelines?per_page=5&page=1`)
      .then((response) => {
        vue.set(that, 'pipelines', JSON.parse(response.body));
      }, () => {
        console.error('API Error for Pipelines');
      });

  gl.PipelineStore = class {
    fetchDataLoop(Vue) {
      setInterval(() => {
        console.log('DID IT');
        goFetch(this, Vue);
      }, 30000);
    }

    fetchCommits(vue) {
      this.$http.get(`/api/v3/projects/${this.scope}/repository/commits?per_page=5&page=1`)
        .then((response) => {
          vue.set(this, 'commits', JSON.parse(response.body));
        }, () => {
          console.error('API Error for Pipelines');
        })
        .then(() => goFetch(this, vue));
    }
  };
})(window.gl || (window.gl = {}));
