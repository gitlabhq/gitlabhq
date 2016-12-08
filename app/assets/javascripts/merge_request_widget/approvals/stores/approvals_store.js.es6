(() => {
  let singleton;

  class ApprovalsStore {
    constructor(rootEl) {
      if (!singleton) {
        singleton = gl.MergeRequestWidget.ApprovalsStore = this;
        this.init(rootEl);
      }
      return singleton;
    }

    init(rootEl) {
    }

    assignToData(val) {
    }

    /** TODO: remove after backend integerated */
    approve() {
    }

    unapprove() {
    }

  }
  gl.MergeRequestWidget.ApprovalsStore = ApprovalsStore;
})();

