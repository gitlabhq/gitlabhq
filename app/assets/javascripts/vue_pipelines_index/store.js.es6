/* global gl */
/* eslint-disable no-param-reassign */

((gl) => {
  const api = '/api/v3/projects';

  gl.PipelineStore = class {
    fetchDataLoop(Vue) {
      const goFetch = () =>
        this.$http.get(
          `${api}/${this.scope}/pipelines?per_page=5&page=1`
        )
          .then((response) => {
            Vue.set(this, 'pipelines', JSON.parse(response.body));
          }, () => {
            console.error('API Error for Pipelines');
          });

      goFetch();

      // eventually clearInterval(this.intervalId)
      this.intervalId = setInterval(() => {
        console.log('DID IT');
        goFetch();
      }, 30000);
    }
  };
})(window.gl || (window.gl = {}));
