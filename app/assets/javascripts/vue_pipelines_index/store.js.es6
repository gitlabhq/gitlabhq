/* global gl, Flash */
/* eslint-disable no-param-reassign, no-underscore-dangle */
/*= require vue_realtime_listener/index.js */

((gl) => {
  const pageValues = (headers) => {
    const normalized = gl.utils.normalizeHeaders(headers);

    const paginationInfo = {
      perPage: +normalized['X-PER-PAGE'],
      page: +normalized['X-PAGE'],
      total: +normalized['X-TOTAL'],
      totalPages: +normalized['X-TOTAL-PAGES'],
      nextPage: +normalized['X-NEXT-PAGE'],
      previousPage: +normalized['X-PREV-PAGE'],
    };

    return paginationInfo;
  };

  gl.PipelineStore = class {
    fetchDataLoop(Vue, pageNum, url, apiScope) {
      const updatePipelineNums = (count) => {
        const { all } = count;
        const running = count.running_or_pending;
        document.querySelector('.js-totalbuilds-count').innerHTML = all;
        document.querySelector('.js-running-count').innerHTML = running;
      };

      const goFetch = () =>
        this.$http.get(`${url}?scope=${apiScope}&page=${pageNum}`)
          .then((response) => {
            const pageInfo = pageValues(response.headers);
            this.pageInfo = Object.assign({}, this.pageInfo, pageInfo);

            const res = JSON.parse(response.body);
            this.count = Object.assign({}, this.count, res.count);
            this.pipelines = Object.assign([], this.pipelines, res.pipelines);

            updatePipelineNums(this.count);
            this.pageRequest = false;
          }, () => {
            this.pageRequest = false;
            return new Flash('Something went wrong on our end.');
          });

      goFetch();

      const startTimeLoops = () => {
        this.timeLoopInterval = setInterval(() => {
          this.$children
            .filter(e => e.$options._componentTag === 'time-ago')
            .forEach(e => e.changeTime());
        }, 10000);
      };

      startTimeLoops();

      const removeIntervals = () => clearInterval(this.timeLoopInterval);
      const startIntervals = () => startTimeLoops();

      gl.VueRealtimeListener(removeIntervals, startIntervals);
    }
  };
})(window.gl || (window.gl = {}));
