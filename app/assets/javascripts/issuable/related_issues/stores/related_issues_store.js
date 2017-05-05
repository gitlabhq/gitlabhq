import {
  FETCH_SUCCESS_STATUS,
  FETCH_ERROR_STATUS,
} from '../constants';
import { assembleDisplayIssuableReference } from '../../../lib/utils/issuable_reference_utils';

class RelatedIssuesStore {
  constructor() {
    this.state = {
      // Stores issue objects that we can lookup by reference
      issueMap: {},
      // Stores references to the actual known related issues
      relatedIssues: [],
      // Stores references to the "staging area" related issues that are planned to be added
      pendingRelatedIssues: [],
    };
  }

  getIssueFromReference(reference, namespacePath, projectPath) {
    const issue = this.state.issueMap[reference];

    let displayReference = reference;
    if (issue && issue.fetchStatus === FETCH_SUCCESS_STATUS) {
      displayReference = assembleDisplayIssuableReference(
        issue,
        namespacePath,
        projectPath,
      );
    }

    const fetchStatus = issue ? issue.fetchStatus : FETCH_ERROR_STATUS;

    return {
      reference,
      displayReference,
      path: issue && issue.path,
      title: issue && issue && issue.title,
      state: issue && issue.state,
      fetchStatus,
      canRemove: issue && issue.destroy_relation_path && issue.destroy_relation_path.length > 0,
    };
  }

  getIssuesFromReferences(references, namespacePath, projectPath) {
    return references.map(reference =>
      this.getIssueFromReference(reference, namespacePath, projectPath));
  }

  addToIssueMap(reference, issue) {
    this.state.issueMap = {
      ...this.state.issueMap,
      [reference]: issue,
    };
  }

  setRelatedIssues(value) {
    this.state.relatedIssues = value;
  }

  setPendingRelatedIssues(issues) {
    this.state.pendingRelatedIssues = issues;
  }
}

export default RelatedIssuesStore;
