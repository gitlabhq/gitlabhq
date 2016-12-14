//= require ../stores/approvals_store

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
      return Vue.http.get(this.baseEndpoint).catch((err) => {
        console.error(`Error fetching approvals. ${err}`);
      });
    }

    approveMergeRequest() {
      return Vue.http.post(this.baseEndpoint).catch((err) => {
        console.error(`Error approving merge request. ${err}`);
      });
    }

    unapproveMergeRequest() {
      return Vue.http.delete(this.baseEndpoint).catch((err) => {
        console.error(`Error unapproving merge request. ${err}`);
      });
    }
  }

  gl.ApprovalsApi = ApprovalsApi;
})();
