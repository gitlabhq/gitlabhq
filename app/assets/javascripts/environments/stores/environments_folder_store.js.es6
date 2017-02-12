require('~/lib/utils/common_utils');
/**
 * Environments Folder Store.
 *
 * Stores received environments that belong to a parent store.
 */
class EnvironmentsFolderStore {
  constructor() {
    this.state = {};
    this.state.environments = [];
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
   *
   * @param  {Array} environments
   * @returns {Array}
   */
  storeEnvironments(environments = []) {
    this.state.environments = environments;

    return environments;
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
}

module.exports = EnvironmentsFolderStore;
