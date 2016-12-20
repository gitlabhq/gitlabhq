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

      return Vue.http.get(this.baseEndpoint).catch((err) => {
        console.error('Error fetching approvals', err);
        return new Flash(flashErrorMessage, 'alert');
      });
    }

    approveMergeRequest() {
      const flashErrorMessage = 'An error occured while submitting your approval.';

      return Vue.http.post(this.baseEndpoint).catch((err) => {
        console.error('Error approving merge request', err);
        return new Flash(flashErrorMessage, 'alert');
      });
    }

    unapproveMergeRequest() {
      const flashErrorMessage = 'An error occured while removing your approval.';

      return Vue.http.delete(this.baseEndpoint).catch((err) => {
        console.error('Error unapproving merge request', err);
        return new Flash(flashErrorMessage, 'alert');
      });
    }
  }

  gl.ApprovalsApi = ApprovalsApi;
})();
