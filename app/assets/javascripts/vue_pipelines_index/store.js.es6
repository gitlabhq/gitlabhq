/* global gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.PipelineStore = class {
    fetchData(Vue) {
      this.$http.get(`/api/v3/projects/${this.scope}/pipelines`)
        .then((response) => {
            Vue.set(this, 'pipelines', JSON.parse(response.body));
          }, () => {
            Vue.set(this, 'pipelines', []);
          });
    }
  };
})(window.gl || (window.gl = {}));
