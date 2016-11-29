//= require ../stores/approvals_store

(() => {
  class ApprovalsService {
    constructor() {
      this.isFetching = false;
      this.hasBeenFetched = true;
    }
    fetchApprovals() {
      return makeRequest().then((data) => {
        this.isFetching = false;
        this.hasBeenFetched = true;
        return data;
      });
    }
    approveMergeRequest(payload) {
      return payload;
    }
    unapproveMergeRequest(payload) {
      return payload;
    }
  }
  gl.mergeRequestWidget.ApprovalsService = ApprovalsService;
})();