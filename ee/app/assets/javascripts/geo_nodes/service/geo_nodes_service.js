import axios from '~/lib/utils/axios_utils';

import Api from '~/api';

export default class GeoNodesService {
  constructor(nodeDetailsBasePath) {
    this.geoNodeDetailsBasePath = nodeDetailsBasePath;
    this.geoNodesPath = Api.buildUrl(Api.geoNodesPath);
  }

  getGeoNodes() {
    return axios.get(this.geoNodesPath);
  }

  getGeoNodeDetails(nodeId) {
    const geoNodeDetailsPath = `${this.geoNodeDetailsBasePath}/${nodeId}/status.json`;
    return axios.get(geoNodeDetailsPath);
  }
}
