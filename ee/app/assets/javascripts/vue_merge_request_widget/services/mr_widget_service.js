import Vue from 'vue';

import CEWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

export default class MRWidgetService extends CEWidgetService {
  constructor(mr) {
    super(mr);

    // Set as a text/plain request so BE doesn't try to parse
    // See https://gitlab.com/gitlab-org/gitlab-ce/issues/34534
    this.approvalsResource = Vue.resource(mr.approvalsPath, {}, {}, {
      headers: {
        'Content-Type': 'text/plain',
      },
    });
    this.rebaseResource = Vue.resource(mr.rebasePath);
  }

  fetchApprovals() {
    return this.approvalsResource.get()
      .then(res => res.json());
  }

  approveMergeRequest() {
    return this.approvalsResource.save()
      .then(res => res.json());
  }

  unapproveMergeRequest() {
    return this.approvalsResource.delete()
      .then(res => res.json());
  }

  rebase() {
    return this.rebaseResource.save();
  }

  fetchCodeclimate(endpoint) { // eslint-disable-line
    return Vue.http.get(endpoint);
  }
}
