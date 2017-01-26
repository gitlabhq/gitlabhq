(() => {
  window.gl = window.gl || {};
  window.gl.issueBoards = window.gl.issueBoards || {};

  class ModalStore {
    constructor() {
      this.store = {
        issues: [],
        selectedIssues: [],
        showAddIssuesModal: false,
        activeTab: 'all',
        selectedList: {},
        searchTerm: '',
        loading: false,
      };
    }

    selectedCount() {
      return this.store.selectedIssues.length;
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
      const select = this.selectedCount() !== this.store.issues.length;

      this.store.issues.forEach((issue) => {
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
      this.store.selectedIssues.push(issue);
    }

    removeSelectedIssue(issue) {
      const index = this.selectedIssueIndex(issue);
      this.store.selectedIssues.splice(index, 1);
    }

    selectedIssueIndex(issue) {
      return this.store.selectedIssues.indexOf(issue);
    }

    findSelectedIssue(issue) {
      return this.store.selectedIssues
        .filter(filteredIssue => filteredIssue.id === issue.id)[0];
    }
  }

  gl.issueBoards.ModalStore = new ModalStore();
})();
