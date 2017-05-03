import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
  }

  // eslint-disable-next-line class-methods-use-this
  fetchIssueInfo(endpoint) {
    return Vue.http.get(endpoint)
      .then(res => res.json());
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get()
      .then(res => res.json());
  }

  addRelatedIssues(newIssueReferences) {
    return this.relatedIssuesResource.save({}, {
      issue_references: newIssueReferences,
    })
      .then(res => res.json());
  }

  // eslint-disable-next-line class-methods-use-this
  removeRelatedIssue(endpoint) {
    return Vue.http.delete(endpoint)
      .then(res => res.json());
  }
}

export default RelatedIssuesService;
