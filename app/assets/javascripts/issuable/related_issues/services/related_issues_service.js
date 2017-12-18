import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
    this.reorderIssuesResource = Vue.resource(`${endpoint}{/id}/order`);
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get();
  }

  addRelatedIssues(newIssueReferences) {
    return this.relatedIssuesResource.save({}, {
      issue_references: newIssueReferences,
    });
  }

  saveIssueOrder(issueId, position) {
    return this.reorderIssuesResource.update({
      id: issueId,
    }, {
      position,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  removeRelatedIssue(endpoint) {
    return Vue.http.delete(endpoint);
  }
}

export default RelatedIssuesService;
