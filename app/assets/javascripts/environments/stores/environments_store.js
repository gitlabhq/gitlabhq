import { setDeployBoard } from 'ee_else_ce/environments/stores/helpers';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

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
   * In the main environments endpoint (with { nested: true } in params), each folder
   * has the following schema:
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
   * keys to those environments.
   * The first key will let's us know if we should or not render the deploy board.
   * It will be toggled when the user clicks to seee the deploy board.
   *
   * The second key will allow us to update the environment with the received deploy board data.
   *
   * @param  {Array} environments
   * @returns {Array}
   */
  storeEnvironments(environments = []) {
    const filteredEnvironments = environments.map(env => {
      const oldEnvironmentState =
        this.state.environments.find(element => {
          if (env.latest) {
            return element.id === env.latest.id;
          }
          return element.id === env.id;
        }) || {};

      let filtered = {};

      if (env.size > 1) {
        filtered = Object.assign({}, env, {
          isFolder: true,
          isLoadingFolderContent: oldEnvironmentState.isLoading || false,
          folderName: env.name,
          isOpen: oldEnvironmentState.isOpen || false,
          children: oldEnvironmentState.children || [],
        });
      }

      if (env.latest) {
        filtered = Object.assign(filtered, env, env.latest);
        delete filtered.latest;
      } else {
        filtered = Object.assign(filtered, env);
      }

      filtered = setDeployBoard(oldEnvironmentState, filtered);
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
    const normalizedHeaders = normalizeHeaders(pagination);
    const paginationInformation = parseIntPagination(normalizedHeaders);

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
    return this.updateEnvironmentProp(folder, 'isOpen', !folder.isOpen);
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
    const updatedEnvironments = environments.map(env => {
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

    return this.updateEnvironmentProp(folder, 'children', updatedEnvironments);
  }

  /**
   * Given a environment,  a prop and a new value updates the correct environment.
   *
   * @param  {Object} environment
   * @param  {String} prop
   * @param  {String|Boolean|Object|Array} newValue
   * @return {Array}
   */
  updateEnvironmentProp(environment, prop, newValue) {
    const { environments } = this.state;

    const updatedEnvironments = environments.map(env => {
      const updateEnv = Object.assign({}, env);
      if (env.id === environment.id) {
        updateEnv[prop] = newValue;
      }

      return updateEnv;
    });

    this.state.environments = updatedEnvironments;
  }

  getOpenFolders() {
    const { environments } = this.state;

    return environments.filter(env => env.isFolder && env.isOpen);
  }
}
