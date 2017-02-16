require('~/lib/utils/common_utils');
/**
 * Environments Store.
 *
 * Stores received environments, count of stopped environments and count of
 * available environments.
 */
class EnvironmentsStore {
  constructor() {
    this.state = {};
    this.state.environments = [];
    this.state.stoppedCounter = 0;
    this.state.availableCounter = 0;
    this.state.paginationInformation = {};

    return this;
  }

  /**
   *
   * Stores the received environments.
   *
   * In the main environments endpoint, each environment has the following schema
   * { name: String, size: Number, latest: Object }
   * In the endpoint to retrieve environments from each folder, the environment does
   * not have the `latest` key and the data is all in the root level.
   * To avoid doing this check in the view, we store both cases the same by extracting
   * what is inside the `latest` key.
   *
   * If the `size` is bigger than 1, it means it should be rendered as a folder.
   * In those cases we add `isFolder` key in order to render it properly.
   *
   * @param  {Array} environments
   * @returns {Array}
   */
  storeEnvironments(environments = []) {
    const filteredEnvironments = environments.map((env) => {
      let filtered = {};

      if (env.size > 1) {
        filtered = Object.assign({}, env, { isFolder: true, folderName: env.name });
      }

      if (env.latest) {
        filtered = Object.assign(filtered, env, env.latest);
        delete filtered.latest;
      } else {
        filtered = Object.assign(filtered, env);
      }

      return filtered;
    });

    this.state.environments = filteredEnvironments;

    return filteredEnvironments;
  }

  setPagination(pagination = {}) {
    const normalizedHeaders = gl.utils.normalizeHeaders(pagination);
    const paginationInformation = gl.utils.parseIntPagination(normalizedHeaders);

    this.state.paginationInformation = paginationInformation;
    return paginationInformation;
  }

  /**
   * Stores the number of available environments.
   *
   * @param  {Number} count = 0
   * @return {Number}
   */
  storeAvailableCount(count = 0) {
    this.state.availableCounter = count;
    return count;
  }

  /**
   * Stores the number of closed environments.
   *
   * @param  {Number} count = 0
   * @return {Number}
   */
  storeStoppedCount(count = 0) {
    this.state.stoppedCounter = count;
    return count;
  }
}

module.exports = EnvironmentsStore;
