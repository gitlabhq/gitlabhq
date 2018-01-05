import axios from '~/lib/utils/axios_utils';

import CEWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

export default class MRWidgetService extends CEWidgetService {
  constructor(mr) {
    super(mr);

    this.approvalsPath = mr.approvalsPath;
  }

  fetchApprovals() {
    return axios.get(this.approvalsPath)
      .then(res => res.data);
  }

  approveMergeRequest() {
    return axios.post(this.approvalsPath)
      .then(res => res.data);
  }

  unapproveMergeRequest() {
    return axios.delete(this.approvalsPath)
      .then(res => res.data);
  }

  fetchReport(endpoint) { // eslint-disable-line
    return axios.get(endpoint)
      .then(res => res.data);
  }
}
