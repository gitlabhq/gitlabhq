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
   * Each environment has the following schema
   * { name: String, size: Number, latest: Object }
   *
   * If the `size` is bigger than 1, it means it should be rendered as a folder.
   * In those cases we add `isFolder` key in order to render it properly.
   *
   * @param  {Array} environments
   * @returns {Array}
   */
  storeEnvironments(environments = []) {
    const filteredEnvironments = environments.map((env) => {
      if (env.size > 1) {
        return Object.assign({}, env, { isFolder: true });
      }

      return env;
    });

    this.state.environments = filteredEnvironments;

    return filteredEnvironments;
  }

  storePagination(pagination = {}) {
    const normalizedHeaders = gl.utils.normalizeHeaders(pagination);
    const paginationInformation = {
      perPage: parseInt(normalizedHeaders['X-PER-PAGE'], 10),
      page: parseInt(normalizedHeaders['X-PAGE'], 10),
      total: parseInt(normalizedHeaders['X-TOTAL'], 10),
      totalPages: parseInt(normalizedHeaders['X-TOTAL-PAGES'], 10),
      nextPage: parseInt(normalizedHeaders['X-NEXT-PAGE'], 10),
      previousPage: parseInt(normalizedHeaders['X-PREV-PAGE'], 10),
    };

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
