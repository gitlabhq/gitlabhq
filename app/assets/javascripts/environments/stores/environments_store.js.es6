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
   * Top level environments - when the size is 1 - with `rollout_status`
   * can render a deploy board. We add `isDeployBoardVisible` and `deployBoardData`
   * keys to those envrionments.
   * The first key will let's us know if we should or not render the deploy board.
   * It will be toggled when the user clicks to seee the deploy board.
   *
   * The second key will allow us to update the environment with the received deploy board data.
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

      // FIX ME
      // no folders items with `x` key can have a deploy board
      if (env.size === 1) {
        filtered = Object.assign({}, env, {
          isDeployBoardVisible: false,
          deployBoardData: {},
          deployBoardEndpoint: `environments/${env.id}/status.json`,
        });
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

  /**
   * Stores the pagination information needed to render the pagination for the
   * table.
   *
   * Normalizes the headers to uppercase since they can be provided either
   * in uppercase or lowercase.
   *
   * Parses to an integer the normalized ones needed for the pagination component.
   *
   * Stores the normalized and parsed information.
   *
   * @param  {Object} pagination = {}
   * @return {Object}
   */
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

  /**
   * Toggles deploy board visibility for the provided environment.
   *
   * @param  {Object} environment
   * @return {Array}
   */
  toggleDeployBoard(environment) {
    const environments = Object.assign([], this.state.environments);

    this.state.environments = environments.map((env) => {
      let updated = Object.assign({}, env);

      if (env.id === environment.id) {
        updated = Object.assign({}, updated, { isDeployBoardVisible: !env.isDeployBoardVisible });
      }
      return updated;
    });

    return this.state.environments;
  }

  storeDeployBoard(environmentID, deployBoard) {
    console.log(environmentID, deployBoard);
  }
}

module.exports = EnvironmentsStore;
