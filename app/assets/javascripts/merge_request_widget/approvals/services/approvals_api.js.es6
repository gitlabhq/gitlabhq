//= require ../stores/approvals_store

// TODO: Determine whether component-specific store should be accessed here as a member
((MergeRequestWidget) => {

  function mockApprovalRequest(payload) {
    const currentPayload = Object.assign({}, payload.data);
    const currentStore = gl.MergeRequestWidget.Store.data.approvals;
    const parsedStore = JSON.parse(JSON.stringify(currentStore));
    const mockResp = Object.assign(currentPayload, parsedStore);

    return new Promise((resolve) => {
      setTimeout(() => {
        resolve(mockResp);
      }, 100);
    });
  }

  class ApprovalsApi {
    constructor() {
      this.store = null;
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
        type: 'PUT',
        data: {
          approve: true,
        },
      };
      return this.genericApprovalRequest(payload);
    }

    unapproveMergeRequest() {
      const payload = {
        type: 'PUT',
        data: {
          approve: false,
        },
      };
      return this.genericApprovalRequest(payload);
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
