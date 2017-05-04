import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
  }

  // eslint-disable-next-line class-methods-use-this
  fetchIssueInfo(endpoint) {
    return Vue.http.get(endpoint);
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get();
  }

  addRelatedIssues(newIssueReferences) {
    return this.relatedIssuesResource.save({}, {
      issue_references: newIssueReferences,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  removeRelatedIssue(endpoint) {
    return Vue.http.delete(endpoint);
  }
}

export default RelatedIssuesService;
