(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  class ModalStore {
    constructor() {
      this.globalStore = gl.issueBoards.BoardsStore.modal;
    }

    selectedCount() {
      return this.globalStore.selectedIssues.length;
    }

    toggleIssue(issueObj) {
      const issue = issueObj;
      issue.selected = !issue.selected;

      if (issue.selected) {
        this.addSelectedIssue(issue);
      } else {
        this.removeSelectedIssue(issue);
      }
    }

    toggleAll() {
      const select = this.selectedCount() !== this.globalStore.issues.length;

      this.globalStore.issues.forEach((issue) => {
        const issueUpdate = issue;

        if (issueUpdate.selected !== select) {
          issueUpdate.selected = select;

          if (select) {
            this.addSelectedIssue(issue);
          } else {
            this.removeSelectedIssue(issue);
          }
        }
      });
    }

    addSelectedIssue(issue) {
      this.globalStore.selectedIssues.push(issue);
    }

    removeSelectedIssue(issue) {
      const index = this.selectedIssueIndex(issue);
      this.globalStore.selectedIssues.splice(index, 1);
    }

    selectedIssueIndex(issue) {
      return this.globalStore.selectedIssues.indexOf(issue);
    }

    findSelectedIssue(issue) {
      return this.globalStore.selectedIssues
        .filter(filteredIssue => filteredIssue.id === issue.id)[0];
    }
  }

  gl.issueBoards.ModalStore = new ModalStore();
})();
