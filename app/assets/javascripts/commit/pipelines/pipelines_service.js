/* globals Vue */
/* eslint-disable no-unused-vars, no-param-reassign */

/**
 * Pipelines service.
 *
 * Used to fetch the data used to render the pipelines table.
 * Uses Vue.Resource
 */
class PipelinesService {

  /**
   * FIXME: The url provided to request the pipelines in the new merge request
   * page already has `.json`.
   * This should be fixed when the endpoint is improved.
   *
   * @param  {String} root
   */
  constructor(root) {
    let endpoint;

    if (root.indexOf('.json') === -1) {
      endpoint = `${root}.json`;
    } else {
      endpoint = root;
    }
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
