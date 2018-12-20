import axios from '~/lib/utils/axios_utils';

export default class GetFunctionsService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  fetchData() {
    return axios.get(this.endpoint);
  }
}
