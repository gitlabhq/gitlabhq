//= require ../stores/approvals_store

(() => {
  class ApprovalsApi {
    constructor(endpoint) {
      gl.ApprovalsApi = this;
      this.init(endpoint);
    }

    init(mergeRequestEndpoint) {
      const approvalsEndpoint = `${mergeRequestEndpoint}/approvals.json`;
      this.resource = gl.ApprovalsResource = new gl.SubbableResource(approvalsEndpoint);
    }

    fetchApprovals() {
      return this.resource.get({ type: 'GET' }).fail((err) => {
        console.error(`Error fetching approvals. ${err}`);
      });
    }

    approveMergeRequest() {
      return this.resource.post({ type: 'POST' }).fail((err) => {
        console.error(`Error approving merge request. ${err}`);
      });
    }

    unapproveMergeRequest() {
      return this.resource.delete({ type: 'DELETE' }).fail((err) => {
        console.error(`Error unapproving merge request. ${err}`);
      });
    }
  }

  gl.ApprovalsApi = ApprovalsApi;
})();
