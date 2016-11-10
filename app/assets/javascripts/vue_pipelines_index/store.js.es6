/* global gl, Flash */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.PipelineStore = class {
    fetchDataLoop(Vue, pageNum, url) {
      const goFetch = () =>
        this.$http.get(`${url}?page=${pageNum}`)
          .then((response) => {
            debugger
            const res = JSON.parse(response.body)
            Vue.set(this, 'pipelines', res.pipelines);
          }, () => new Flash(
            'Something went wrong on our end.'
          ));

      goFetch();

      this.intervalId = setInterval(() => {
        goFetch();
      }, 3000);
    }
  };
})(window.gl || (window.gl = {}));
