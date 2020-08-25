import axios from '~/lib/utils/axios_utils';
import { linkedIssueTypesMap } from '../constants';

class RelatedIssuesService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  fetchRelatedIssues() {
    return axios.get(this.endpoint);
  }

  addRelatedIssues(newIssueReferences, linkType = linkedIssueTypesMap.RELATES_TO) {
    return axios.post(this.endpoint, {
      issuable_references: newIssueReferences,
      link_type: linkType,
    });
  }

  static saveOrder({ endpoint, move_before_id, move_after_id }) {
    return axios.put(endpoint, {
      epic: {
        move_before_id,
        move_after_id,
      },
    });
  }

  static remove(endpoint) {
    return axios.delete(endpoint);
  }
}

export default RelatedIssuesService;
