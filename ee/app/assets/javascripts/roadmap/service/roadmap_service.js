import axios from '~/lib/utils/axios_utils';

export default class RoadmapService {
  constructor(epicsPath) {
    this.epicsPath = epicsPath;
  }

  getEpics() {
    return axios.get(this.epicsPath);
  }
}
