/* eslint-disable no-param-reassign */

((gl) => {
  gl.PollingPipelines = class {
    constructor(pipelines = false, count = false) {
      this.pipelines = pipelines;
      this.count = count;

      if (!this.pipelines && !this.count) return;

      this.pipelinesOnDOM = document.querySelectorAll('.commit-link');
      this.DOMPipelineStatuses = [];

      this.storePipelineStatuses();
      this.checkStatusChanges();
      setTimeout(() => this.applyNewStatusChanges(), 3000);
    }

    storePipelineStatuses() {
      if (this.count) {
        this.pipelinesOnDOM.forEach((e) => {
          this.DOMPipelineStatuses.push(
            e.children[0].childNodes[0].classList[1].split('-')[1]
          );
        });
      }
    }

    checkStatusChanges() {
      const newChanges = this.updatePipelines()
        .map((e, i) => {
          if (this.pipelines[i].status !== e.status) return 1;
          return 0;
        })
        .reduce((a, b) => a + b);

      if (newChanges > 0) return true;
      return false;
    }

    updatePipelines() {
      // this is mocking the API for now
      // no way to test this until API is built
      // using 'mock' data
      const apiPipelines = this.pipelines;
      apiPipelines[0].status = 'failed';
      // end of 'mock' data
      this.pipelines = apiPipelines;
      return apiPipelines;
    }

    applyNewStatusChanges() {
      this.pipelinesOnDOM.forEach((e, i) => {
        const newStatus = `ci-status ci-${this.pipelines[i].status}`;
        // needs to be explicitly called
        // cannot ask `currentDomStatus` to change
        e.children[0].childNodes[0].className = newStatus;
      });
    }
  };
})(window.gl || (window.gl = {}));
