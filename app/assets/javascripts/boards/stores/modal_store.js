class ModalStore {
  constructor() {
    this.store = {
      columns: 3,
      issues: [],
      issuesCount: false,
      selectedIssues: [],
      showAddIssuesModal: false,
      activeTab: 'all',
      selectedList: null,
      searchTerm: '',
      loading: false,
      loadingNewPage: false,
      filterLoading: false,
      page: 1,
      perPage: 50,
      filter: {
        path: '',
      },
    };
  }

  selectedCount() {
    return this.getSelectedIssues().length;
  }

  toggleIssue(issueObj) {
    const issue = issueObj;
    const selected = issue.selected;

    issue.selected = !selected;

    if (!selected) {
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
      this.store.selectedIssues = this.store.selectedIssues
        .filter(fIssue => fIssue.id !== issue.id);
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

export default new ModalStore();
