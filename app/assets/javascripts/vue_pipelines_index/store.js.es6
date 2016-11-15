/* global gl, Flash */
/* eslint-disable no-param-reassign */

((gl) => {
  class PipelineUpdater {
    constructor(pipelines) {
      this.pipelines = pipelines;
      this.updateClone = (update, newPipe) => {
        update.forEach((pipe) => {
          if (pipe.id === newPipe.id) pipe = Object.assign(pipe, newPipe);
        });
      };
    }

    updatePipelines(apiResponse) {
      const update = this.pipelines.map(e => e);
      apiResponse.pipelines.forEach((newPipe) => {
        if (newPipe.commit) {
          update.unshift(newPipe);
        } else {
          this.updateClone(update, newPipe);
        }
      });
      this.pipelines = update;
      return this.pipelines;
    }
  }

  gl.PipelineStore = class {
    fetchDataLoop(Vue, pageNum, url) {
      Vue.activeResources = 0;
      const resourceChecker = () => {
        if (Vue.activeResources === 0) {
          Vue.activeResources = 1;
        } else {
          Vue.activeResources += 1;
        }
      };

      const goFetch = () =>
        this.$http.get(`${url}?page=${pageNum}`)
          .then((response) => {
            const res = JSON.parse(response.body);
            Vue.set(this, 'updatedAt', res.updated_at);
            Vue.set(this, 'pipelines', res.pipelines);
            Vue.set(this, 'count', res.count);
            this.pageRequest = false;
            Vue.activeResources -= 1;
          }, () => new Flash(
            'Something went wrong on our end.'
          ));

      const goUpdate = () =>
        this.$http.get(`${url}?page=${pageNum}&updated_at=${this.updatedAt}`)
          .then((response) => {
            const res = JSON.parse(response.body);
            const p = new PipelineUpdater(this.pipelines);
            Vue.set(this, 'updatedAt', res.updated_at);
            Vue.set(this, 'pipelines', p.updatePipelines(res));
            Vue.set(this, 'count', res.count);
            Vue.activeResources -= 1;
          }, () => new Flash(
            'Something went wrong on our end.'
          ));

      resourceChecker();
      goFetch();

      this.intervalId = setInterval(() => {
        if (this.updatedAt) {
          resourceChecker();
          goUpdate();
        }
      }, 3000);

      window.onbeforeunload = function removePipelineInterval() {
        clearInterval(this.intervalId);
      };
    }
  };
})(window.gl || (window.gl = {}));
