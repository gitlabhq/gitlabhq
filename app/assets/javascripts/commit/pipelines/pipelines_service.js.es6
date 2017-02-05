/* globals Vue */
/* eslint-disable no-unused-vars, no-param-reassign */

/**
 * Pipelines service.
 *
 * Used to fetch the data used to render the pipelines table.
 * Uses Vue.Resource
 */
class PipelinesService {
  constructor(endpoint) {
    this.pipelines = Vue.resource(endpoint);
  }

  /**
   * Given the root param provided when the class is initialized, will
   * make a GET request.
   *
   * @return {Promise}
   */
  all() {
    return this.pipelines.get();
  }
}

window.gl = window.gl || {};
gl.commits = gl.commits || {};
gl.commits.pipelines = gl.commits.pipelines || {};
gl.commits.pipelines.PipelinesService = PipelinesService;
