import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

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
    this.state.relatedIssues = convertObjectPropsToCamelCase(issues, { deep: true });
  }

  addRelatedIssues(issues = []) {
    this.setRelatedIssues(this.state.relatedIssues.concat(issues));
  }

  removeRelatedIssue(issue) {
    this.state.relatedIssues = this.state.relatedIssues.filter((x) => x.id !== issue.id);
  }

  updateIssueOrder(oldIndex, newIndex) {
    if (this.state.relatedIssues.length > 0) {
      const updatedIssue = this.state.relatedIssues.splice(oldIndex, 1)[0];
      this.state.relatedIssues.splice(newIndex, 0, updatedIssue);
    }
  }

  setPendingReferences(issues) {
    // Remove duplicates but retain order.
    // If you don't do this, Vue will be confused by duplicates and refuse to delete them all.
    this.state.pendingReferences = issues.filter((ref, idx) => issues.indexOf(ref) === idx);
  }

  addPendingReferences(references = []) {
    const issues = this.state.pendingReferences.concat(references);
    this.setPendingReferences(issues);
  }

  removePendingRelatedIssue(indexToRemove) {
    this.state.pendingReferences = this.state.pendingReferences.filter(
      (reference, index) => index !== indexToRemove,
    );
  }
}

export default RelatedIssuesStore;
