import Vue from 'vue';

export default class PipelineStore {
  constructor() {
    this.state = {};
    this.state.pipeline = {};
    this.state.expandedPipelines = [];
  }
  /**
   * For the triggered pipelines adds the `isExpanded` key
   *
   * For the triggered_by pipeline adds the `isExpanded` key
   * and saves it as an array
   *
   * @param {Object} pipeline
   */
  storePipeline(pipeline = {}) {
    const pipelineCopy = { ...pipeline };

    if (pipelineCopy.triggered_by) {
      pipelineCopy.triggered_by = [pipelineCopy.triggered_by];

      const oldTriggeredBy =
        this.state.pipeline &&
        this.state.pipeline.triggered_by &&
        this.state.pipeline.triggered_by[0];

      this.parseTriggeredByPipelines(oldTriggeredBy, pipelineCopy.triggered_by[0]);
    }

    if (pipelineCopy.triggered && pipelineCopy.triggered.length) {
      pipelineCopy.triggered.forEach(el => {
        const oldPipeline =
          this.state.pipeline &&
          this.state.pipeline.triggered &&
          this.state.pipeline.triggered.find(element => element.id === el.id);

        this.parseTriggeredPipelines(oldPipeline, el);
      });
    }

    this.state.pipeline = pipelineCopy;
  }

  /**
   * Recursiverly parses the triggered by pipelines.
   *
   * Sets triggered_by as an array, there is always only 1 triggered_by pipeline.
   * Adds key `isExpanding`
   * Keeps old isExpading value due to polling
   *
   * @param {Array} parentPipeline
   * @param {Object} pipeline
   */
  parseTriggeredByPipelines(oldPipeline = {}, newPipeline) {
    // keep old value in case it's opened because we're polling
    Vue.set(newPipeline, 'isExpanded', oldPipeline.isExpanded || false);
    // add isLoading property
    Vue.set(newPipeline, 'isLoading', false);

    // Because there can only ever be one `triggered_by` for any given pipeline,
    // the API returns an object for the value instead of an Array. However,
    // it's easier to deal with an array in the FE so we convert it.
    if (newPipeline.triggered_by) {
      if (!Array.isArray(newPipeline.triggered_by)) {
        Object.assign(newPipeline, { triggered_by: [newPipeline.triggered_by] });
      }

      if (newPipeline.triggered_by?.length > 0) {
        newPipeline.triggered_by.forEach(el => {
          const oldTriggeredBy = oldPipeline.triggered_by?.find(element => element.id === el.id);
          this.parseTriggeredPipelines(oldTriggeredBy, el);
        });
      }
    }
  }

  /**
   * Recursively parses the triggered pipelines
   * @param {Array} parentPipeline
   * @param {Object} pipeline
   */
  parseTriggeredPipelines(oldPipeline = {}, newPipeline) {
    // keep old value in case it's opened because we're polling
    Vue.set(newPipeline, 'isExpanded', oldPipeline.isExpanded || false);

    // add isLoading property
    Vue.set(newPipeline, 'isLoading', false);

    if (newPipeline.triggered && newPipeline.triggered.length > 0) {
      newPipeline.triggered.forEach(el => {
        const oldTriggered =
          oldPipeline.triggered && oldPipeline.triggered.find(element => element.id === el.id);
        this.parseTriggeredPipelines(oldTriggered, el);
      });
    }
  }

  /**
   * Recursively resets all triggered by pipelines
   *
   * @param {Object} pipeline
   */
  resetTriggeredByPipeline(parentPipeline, pipeline) {
    parentPipeline.triggered_by.forEach(el => this.closePipeline(el));

    if (pipeline.triggered_by && pipeline.triggered_by) {
      this.resetTriggeredByPipeline(pipeline, pipeline.triggered_by);
    }
  }

  /**
   * Opens the clicked pipeline and closes all other ones.
   * @param {Object} pipeline
   */
  openTriggeredByPipeline(parentPipeline, pipeline) {
    // first we need to reset all triggeredBy pipelines
    this.resetTriggeredByPipeline(parentPipeline, pipeline);

    this.openPipeline(pipeline);
  }

  /**
   * On click, will close the given pipeline and all nested triggered by pipelines
   *
   * @param {Object} pipeline
   */
  closeTriggeredByPipeline(pipeline) {
    this.closePipeline(pipeline);

    if (pipeline.triggered_by && pipeline.triggered_by.length) {
      pipeline.triggered_by.forEach(triggeredBy => this.closeTriggeredByPipeline(triggeredBy));
    }
  }

  /**
   * Recursively closes all triggered pipelines for the given one.
   *
   * @param {Object} pipeline
   */
  resetTriggeredPipelines(parentPipeline, pipeline) {
    parentPipeline.triggered.forEach(el => this.closePipeline(el));

    if (pipeline.triggered && pipeline.triggered.length) {
      pipeline.triggered.forEach(el => this.resetTriggeredPipelines(pipeline, el));
    }
  }

  /**
   * Opens the clicked triggered pipeline and closes all other ones.
   *
   * @param {Object} pipeline
   */
  openTriggeredPipeline(parentPipeline, pipeline) {
    this.resetTriggeredPipelines(parentPipeline, pipeline);

    this.openPipeline(pipeline);
  }

  /**
   * On click, will close the given pipeline and all the nested triggered ones
   * @param {Object} pipeline
   */
  closeTriggeredPipeline(pipeline) {
    this.closePipeline(pipeline);

    if (pipeline.triggered && pipeline.triggered.length) {
      pipeline.triggered.forEach(triggered => this.closeTriggeredPipeline(triggered));
    }
  }

  /**
   * Utility function, Closes the given pipeline
   * @param {Object} pipeline
   */
  closePipeline(pipeline) {
    Vue.set(pipeline, 'isExpanded', false);
    // remove the pipeline from the parameters
    this.removeExpandedPipelineToRequestData(pipeline.id);
  }

  /**
   * Utility function, Opens the given pipeline
   * @param {Object} pipeline
   */
  openPipeline(pipeline) {
    Vue.set(pipeline, 'isExpanded', true);
    // add the pipeline to the parameters
    this.addExpandedPipelineToRequestData(pipeline.id);
  }
  // eslint-disable-next-line class-methods-use-this
  toggleLoading(pipeline) {
    Vue.set(pipeline, 'isLoading', !pipeline.isLoading);
  }

  addExpandedPipelineToRequestData(id) {
    this.state.expandedPipelines.push(id);
  }

  removeExpandedPipelineToRequestData(id) {
    this.state.expandedPipelines.splice(this.state.expandedPipelines.findIndex(el => el === id), 1);
  }
}
