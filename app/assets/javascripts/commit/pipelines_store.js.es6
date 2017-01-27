/* global gl, Flash */
/* eslint-disable no-param-reassign, no-underscore-dangle */
/*= require vue_realtime_listener/index.js */

/**
 * Pipelines' Store for commits view.
 *
 * Used to store the Pipelines rendered in the commit view in the pipelines table.
 *
 * TODO: take care of timeago instances in here
 */

(() => {
  const CommitPipelineStore = {
    state: {},

    create() {
      this.state.pipelines = [];

      return this;
    },

    storePipelines(pipelines = []) {
      this.state.pipelines = pipelines;
      return pipelines;
    },
  };

  return CommitPipelineStore;
})();
