import axios from '~/lib/utils/axios_utils';

export default class NewEpicService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  createEpic(title) {
    return axios.post(this.endpoint, {
      title,
    });
  }
}
