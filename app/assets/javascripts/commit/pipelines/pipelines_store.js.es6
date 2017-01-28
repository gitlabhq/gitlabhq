/* global gl, Flash */
/* eslint-disable no-param-reassign, no-underscore-dangle */
/*= require vue_realtime_listener/index.js */

/**
 * Pipelines' Store for commits view.
 *
 * Used to store the Pipelines rendered in the commit view in the pipelines table.
 */

(() => {
  window.gl = window.gl || {};
  gl.commits = gl.commits || {};
  gl.commits.pipelines = gl.commits.pipelines || {};

  gl.commits.pipelines.PipelinesStore = {
    state: {},

    create() {
      this.state.pipelines = [];

      return this;
    },

    store(pipelines = []) {
      this.state.pipelines = pipelines;
      return pipelines;
    },
  };
})();
