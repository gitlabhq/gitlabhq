import axios from '~/lib/utils/axios_utils';

export default class EnvironmentsService {
  constructor(endpoint) {
    this.environmentsEndpoint = endpoint;
    this.folderResults = 3;
  }

  fetchEnvironments(options = {}) {
    const { scope, page } = options;
    return axios.get(this.environmentsEndpoint, { params: { scope, page } });
  }

  // eslint-disable-next-line class-methods-use-this
  postAction(endpoint) {
    return axios.post(endpoint, {});
  }

  getFolderContent(folderUrl) {
    return axios.get(`${folderUrl}.json?per_page=${this.folderResults}`);
  }
}
