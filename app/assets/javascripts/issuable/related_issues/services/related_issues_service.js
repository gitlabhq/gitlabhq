import Vue from 'vue';
import vueResource from 'vue-resource';

Vue.use(vueResource);

class RelatedIssuesService {
  constructor(endpoint) {
    this.relatedIssuesResource = Vue.resource(endpoint);
  }

  fetchRelatedIssues() {
    return this.relatedIssuesResource.get();
  }

  addRelatedIssues(newIssueReferences) {
    return this.relatedIssuesResource.save({}, {
      issue_references: newIssueReferences,
    });
  }

  static saveOrder({ endpoint, position }) {
    return Vue.http.put(endpoint, {
      epic: {
        position,
      },
    });
  }

  static remove(endpoint) {
    return Vue.http.delete(endpoint);
  }
}

export default RelatedIssuesService;
