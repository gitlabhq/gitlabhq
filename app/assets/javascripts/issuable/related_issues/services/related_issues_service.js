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

  static saveOrder({ endpoint, move_before_id, move_after_id }) {
    return Vue.http.put(endpoint, {
      epic: {
        move_before_id,
        move_after_id,
      },
    });
  }

  static remove(endpoint) {
    return Vue.http.delete(endpoint);
  }
}

export default RelatedIssuesService;
