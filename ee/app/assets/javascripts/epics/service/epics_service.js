import axios from '~/lib/utils/axios_utils';

export default class EpicsService {
  constructor({ endpoint }) {
    this.endpoint = endpoint;
  }

  updateStatus(stateEventType) {
    const queryParam = `epic[state_event]=${stateEventType}`;
    return axios.put(`${this.endpoint}.json?${encodeURI(queryParam)}`);
  }
}
