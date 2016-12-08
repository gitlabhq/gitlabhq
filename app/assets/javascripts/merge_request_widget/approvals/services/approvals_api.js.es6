//= require ../stores/approvals_store
//= require subbable_resource

(() => {
  class ApprovalsApi {
    constructor() {
      this.resource = gl.ApprovalsResource = new gl.SubbableResource('my/endpoint');
      this.store = gl.MergeRequestWidget.ApprovalsStore;
    }

    fetchApprovals() {
      return this.resource.get();
    }

    approveMergeRequest() {
      return this.resource.post().then(() => {
        gl.MergeRequestWidget.ApprovalsStore.approve();
      });
    }

    unapproveMergeRequest() {
      return this.resource.delete().then(() => {
        gl.MergeRequestWidget.ApprovalsStore.unapprove();
      });
    }

    updateStore(newState = {}) {
      this.store = gl.MergeRequestWidget.Store.data.approvals;
      return Object.assign(this.store, newState);
    }

  }
  gl.MergeRequestWidget.ApprovalsApi = new ApprovalsApi();
})();
