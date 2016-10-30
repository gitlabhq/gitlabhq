/* global gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.PipelineStore = class {
    fetchData(Vue) {
      const goFetch = vue =>
        this.$http.get(`/api/v3/projects/${this.scope}/pipelines`)
          .then((response) => {
            vue.set(this, 'pipelines', JSON.parse(response.body));
          }, () => {
            vue.set(this, 'pipelines', []);
          });

      goFetch(Vue);

      setInterval(() => { console.log('DID IT'); goFetch(Vue) }, 3000);
    }
  };
})(window.gl || (window.gl = {}));
