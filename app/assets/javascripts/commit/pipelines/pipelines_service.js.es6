/* globals Vue */
/* eslint-disable no-unused-vars, no-param-reassign */

/**
 * Pipelines service.
 *
 * Used to fetch the data used to render the pipelines table.
 * Uses Vue.Resource
 */
class PipelinesService {
  constructor(root) {
    Vue.http.options.root = root;

    this.pipelines = Vue.resource(root);

    Vue.http.interceptors.push((request, next) => {
      // needed in order to not break the tests.
      if ($.rails) {
        request.headers['X-CSRF-Token'] = $.rails.csrfToken();
      }
      next();
    });
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
