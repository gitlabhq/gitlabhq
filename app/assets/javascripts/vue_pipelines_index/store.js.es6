/* global gl, Flash */
/* eslint-disable no-param-reassign, no-underscore-dangle */

((gl) => {
  const pageValues = (headers) => {
    const values = {};
    values.perPage = +headers['X-Per-Page'];
    values.page = +headers['X-Page'];
    values.total = +headers['X-Total'];
    values.totalPages = +headers['X-Total-Pages'];
    values.nextPage = +headers['X-Next-Page'];
    values.previousPage = +headers['X-Prev-Page'];
    return values;
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
            Vue.set(this, 'pageInfo', pageInfo);

            const res = JSON.parse(response.body);
            Vue.set(this, 'pipelines', res.pipelines);
            Vue.set(this, 'count', res.count);

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
        }, 1000);
      };

      startTimeLoops();

      const removeTimeIntervals = () => {
        clearInterval(this.timeLoopInterval);
      };

      const startIntervalLoops = () => {
        startTimeLoops();
      };

      const removeAll = () => {
        removeTimeIntervals();
        window.removeEventListener('beforeunload', () => {});
        window.removeEventListener('focus', () => {});
        window.removeEventListener('blur', () => {});

        // turbolinks event handler
        document.removeEventListener('page:fetch', () => {});
      };

      window.addEventListener('beforeunload', removeTimeIntervals);
      window.addEventListener('focus', startIntervalLoops);
      window.addEventListener('blur', removeTimeIntervals);

      // turbolinks event handler
      document.addEventListener('page:fetch', removeAll);
    }
  };
})(window.gl || (window.gl = {}));
