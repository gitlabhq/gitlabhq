//= require ../stores/approvals_store
//= require subbable_resource

(() => {
  class ApprovalsApi {
    constructor(endpoint) {
      gl.ApprovalsApi = this;
      this.init(endpoint);
    }

    init(mergeRequestEndpoint) {
      const approvalsEndpoint = `${mergeRequestEndpoint}/approvals`;
      this.resource = gl.ApprovalsResource = new gl.SubbableResource(approvalsEndpoint);
    }

    fetchApprovals() {
      return this.resource.get().fail((err) => {
        console.error(`Error fetching approvals. ${err}`);
      });
    }

    approveMergeRequest() {
      return this.resource.post().fail((err) => {
        console.error(`Error approving merge request. ${err}`);
      });

    }

    unapproveMergeRequest() {
      return this.resource.delete().fail((err) => {
        console.error(`Error unapproving merge request. ${err}`);
      });
    }
  }

  gl.ApprovalsApi = ApprovalsApi;
})();
