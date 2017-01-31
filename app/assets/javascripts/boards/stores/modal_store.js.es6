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
        loadingNewPage: false,
        page: 1,
        perPage: 50,
      };
    }

    selectedCount() {
      return this.store.selectedIssues.filter(issue => issue.selected).length;
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

    getSelectedIssues() {
      return this.store.selectedIssues.filter(issue => issue.selected);
    }

    addSelectedIssue(issue) {
      const index = this.selectedIssueIndex(issue);

      if (index === -1) {
        this.store.selectedIssues.push(issue);
      }
    }

    removeSelectedIssue(issue, forcePurge = false) {
      if (this.store.activeTab === 'all' || forcePurge) {
        this.store.selectedIssues = this.store.selectedIssues.filter((fIssue) => {
          return fIssue.id !== issue.id;
        });
      }
    }

    purgeUnselectedIssues() {
      this.store.selectedIssues.forEach((issue) => {
        if (!issue.selected) {
          this.removeSelectedIssue(issue, true);
        }
      });
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
