//= require ../stores/approvals_store

(() => {
  class ApprovalsApi {
    constructor(endpoint) {
      gl.ApprovalsApi = this;
      this.init(endpoint);
    }

    init(mergeRequestEndpoint) {
      this.baseEndpoint = mergeRequestEndpoint;
    }

    fetchApprovals() {
      const endpoint = `${this.baseEndpoint}/approvals`;
      return Vue.http.get(endpoint).catch((err) => {
        console.error(`Error fetching approvals. ${err}`);
      });
    }

    approveMergeRequest() {
      const endpoint = `${this.baseEndpoint}/approvals`;
      return Vue.http.save(endpoint).catch((err) => {
        console.error(`Error approving merge request. ${err}`);
      });
    }

    unapproveMergeRequest() {
      const endpoint = `${this.baseEndpoint}/approvals`;
      return Vue.http.delete(endpoint).catch((err) => {
        console.error(`Error unapproving merge request. ${err}`);
      });
    }
  }

  gl.ApprovalsApi = ApprovalsApi;
})();
