//= require ../stores/approvals_store

// TODO: Determine whether component-specific store should be accessed here as a member

((MergeRequestWidget) => {

  function mockApprovalRequest(payload) {
    const store = gl.MergeRequestWidget.Store;

    return new Promise((resolve) => {
      const approvalsStore = store.data.approvals;

      setTimeout(() => {
        resolve(approvalsStore);
      }, 100);
    });
  }

  class ApprovalsApi {
    constructor() {
      this.store = gl.MergeRequestWidget.ApprovalsStore;
      this.isFetching = false;
      this.hasBeenFetched = true;
    }

    fetchApprovals() {
      const payload = {
        type: 'GET',
      };
      return this.genericApprovalRequest(payload);
    }

    approveMergeRequest() {
      const payload = {
        type: 'POST',
      };
      return this.genericApprovalRequest(payload).then(() => {
        gl.MergeRequestWidget.ApprovalsStore.approve();
      });
    }

    unapproveMergeRequest() {
      const payload = {
        type: 'DELETE',
      };
      return this.genericApprovalRequest(payload).then(() => {
        gl.MergeRequestWidget.ApprovalsStore.unapprove();
      });
    }

    genericApprovalRequest(payload = {}) {
      return mockApprovalRequest(payload)
        .then(resp => this.updateStore(resp))
        .catch((err) => {
          throw err;
        });
    }

    updateStore(newState = {}) {
      this.store = gl.MergeRequestWidget.Store.data.approvals; // Always update shared store
      return Object.assign(this.store, newState);
    }

  }
  gl.MergeRequestWidget.ApprovalsApi = new ApprovalsApi();
})(gl.MergeRequestWidget || (gl.MergeRequestWidget = {}));
