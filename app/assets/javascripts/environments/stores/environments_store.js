import '~/lib/utils/common_utils';
/**
 * Environments Store.
 *
 * Stores received environments, count of stopped environments and count of
 * available environments.
 */
export default class EnvironmentsStore {
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
        filtered = Object.assign({}, env, {
          isFolder: true,
          folderName: env.name,
          isOpen: false,
          children: [],
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
    * Toggles folder open property for the given folder.
    *
    * @param  {Object} folder
    * @return {Array}
    */
  toggleFolder(folder) {
    return this.updateFolder(folder, 'isOpen', !folder.isOpen);
  }

  /**
   * Updates the folder with the received environments.
   *
   *
   * @param  {Object} folder       Folder to update
   * @param  {Array} environments Received environments
   * @return {Object}
   */
  setfolderContent(folder, environments) {
    const updatedEnvironments = environments.map((env) => {
      let updated = env;

      if (env.latest) {
        updated = Object.assign({}, env, env.latest);
        delete updated.latest;
      } else {
        updated = env;
      }

      updated.isChildren = true;

      return updated;
    });

    return this.updateFolder(folder, 'children', updatedEnvironments);
  }

  /**
   * Given a folder a prop and a new value updates the correct folder.
   *
   * @param  {Object} folder
   * @param  {String} prop
   * @param  {String|Boolean|Object|Array} newValue
   * @return {Array}
   */
  updateFolder(folder, prop, newValue) {
    const environments = this.state.environments;

    const updatedEnvironments = environments.map((env) => {
      const updateEnv = Object.assign({}, env);
      if (env.isFolder && env.id === folder.id) {
        updateEnv[prop] = newValue;
      }

      return updateEnv;
    });

    this.state.environments = updatedEnvironments;

    return updatedEnvironments;
  }

  getOpenFolders() {
    const environments = this.state.environments;

    return environments.filter(env => env.isFolder && env.isOpen);
  }

}
