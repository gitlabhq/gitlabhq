import axios from '../../lib/utils/axios_utils';

export default class MRWidgetService {
  constructor(endpoints) {
    this.endpoints = endpoints;
  }

  merge(data) {
    return axios.post(this.endpoints.mergePath, data);
  }

  cancelAutomaticMerge() {
    return axios.post(this.endpoints.cancelAutoMergePath);
  }

  removeWIP() {
    return axios.post(this.endpoints.removeWIPPath);
  }

  removeSourceBranch() {
    return axios.delete(this.endpoints.sourceBranchPath);
  }

  fetchDeployments(targetParam) {
    return axios.get(this.endpoints.ciEnvironmentsStatusPath, {
      params: {
        environment_target: targetParam,
      },
    });
  }

  poll() {
    return axios.get(this.endpoints.mergeRequestBasicPath);
  }

  checkStatus() {
    // two endpoints are requested in order to get MR info:
    // one which is etag-cached and invalidated and another one which is not cached
    // the idea is to move all the fields to etag-cached endpoint and then perform only one request
    // https://gitlab.com/gitlab-org/gitlab-foss/issues/61559#note_188801390
    const getData = axios.get(this.endpoints.mergeRequestWidgetPath);
    const getCachedData = axios.get(this.endpoints.mergeRequestCachedWidgetPath);

    return axios
      .all([getData, getCachedData])
      .then(axios.spread((res, cachedRes) => ({ data: Object.assign(res.data, cachedRes.data) })));
  }

  fetchMergeActionsContent() {
    return axios.get(this.endpoints.mergeActionsContentPath);
  }

  rebase() {
    return axios.post(this.endpoints.rebasePath);
  }

  static stopEnvironment(url) {
    return axios.post(url);
  }

  static fetchMetrics(metricsUrl) {
    return axios.get(`${metricsUrl}.json`);
  }

  static fetchInitialData() {
    return Promise.all([
      axios.get(window.gl.mrWidgetData.merge_request_cached_widget_path),
      axios.get(window.gl.mrWidgetData.merge_request_widget_path),
    ]).then(axios.spread((res, cachedRes) => ({ data: Object.assign(res.data, cachedRes.data) })));
  }
}
