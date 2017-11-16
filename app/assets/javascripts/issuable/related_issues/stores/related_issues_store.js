class RelatedIssuesStore {
  constructor() {
    this.state = {
      // Stores issue objects of the known related issues
      relatedIssues: [],
      // Stores references of the "staging area" related issues that are planned to be added
      pendingReferences: [],
    };
  }

  setRelatedIssues(issues = []) {
    this.state.relatedIssues = issues;
  }

  removeRelatedIssue(idToRemove) {
    this.state.relatedIssues = this.state.relatedIssues.filter(issue => issue.id !== idToRemove);
  }

  setPendingReferences(issues) {
    this.state.pendingReferences = issues;
  }

  removePendingRelatedIssue(indexToRemove) {
    this.state.pendingReferences =
      this.state.pendingReferences.filter((reference, index) => index !== indexToRemove);
  }

}

export default RelatedIssuesStore;
