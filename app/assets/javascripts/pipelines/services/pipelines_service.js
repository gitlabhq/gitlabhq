import axios from '../../lib/utils/axios_utils';

export default class PipelinesService {
  /**
   * Commits and merge request endpoints need to be requested with `.json`.
   *
   * The url provided to request the pipelines in the new merge request
   * page already has `.json`.
   *
   * @param  {String} root
   */
  constructor(root) {
    if (root.indexOf('.json') === -1) {
      this.endpoint = `${root}.json`;
    } else {
      this.endpoint = root;
    }
  }

  getPipelines(data = {}) {
    const { scope, page } = data;
    return axios.get(this.endpoint, {
      params: { scope, page },
    });
  }

  /**
   * Post request for all pipelines actions.
   *
   * @param  {String} endpoint
   * @return {Promise}
   */
  // eslint-disable-next-line class-methods-use-this
  postAction(endpoint) {
    return axios.post(`${endpoint}.json`);
  }
}
