/* global Vue, Flash */
//= require ./approvals_store

(() => {
  class ApprovalsApi {
    constructor(endpoint) {
      gl.ApprovalsApi = this;
      this.init(endpoint);
    }

    init(mergeRequestEndpoint) {
      this.baseEndpoint = `${mergeRequestEndpoint}/approvals`;
      Vue.http.headers.common['X-CSRF-Token'] = $.rails.csrfToken();
    }

    fetchApprovals() {
      const flashErrorMessage = 'An error occured while retrieving approval data for this merge request.';

      return Vue.http.get(this.baseEndpoint).catch(() => new Flash(flashErrorMessage));
    }

    approveMergeRequest() {
      const flashErrorMessage = 'An error occured while submitting your approval.';

      return Vue.http.post(this.baseEndpoint).catch(() => new Flash(flashErrorMessage));
    }

    unapproveMergeRequest() {
      const flashErrorMessage = 'An error occured while removing your approval.';

      return Vue.http.delete(this.baseEndpoint).catch(() => new Flash(flashErrorMessage));
    }
  }

  gl.ApprovalsApi = ApprovalsApi;
})();
