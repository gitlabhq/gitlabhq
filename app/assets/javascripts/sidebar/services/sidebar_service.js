import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import reviewerRereviewMutation from '../queries/reviewer_rereview.mutation.graphql';

export const gqClient = createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

export default class SidebarService {
  constructor(endpointMap) {
    if (!SidebarService.singleton) {
      this.endpoint = endpointMap.endpoint;
      this.moveIssueEndpoint = endpointMap.moveIssueEndpoint;
      this.projectsAutocompleteEndpoint = endpointMap.projectsAutocompleteEndpoint;
      this.fullPath = endpointMap.fullPath;
      this.iid = endpointMap.iid;
      this.issuableType = endpointMap.issuableType;

      SidebarService.singleton = this;
    }

    // eslint-disable-next-line no-constructor-return
    return SidebarService.singleton;
  }

  get() {
    return axios.get(this.endpoint);
  }

  update(key, data) {
    return axios.put(this.endpoint, { [key]: data });
  }

  getProjectsAutocomplete(searchTerm) {
    return axios.get(this.projectsAutocompleteEndpoint, {
      params: {
        search: searchTerm,
      },
    });
  }

  moveIssue(moveToProjectId) {
    return axios.post(this.moveIssueEndpoint, {
      move_to_project_id: moveToProjectId,
    });
  }

  requestReview(userId) {
    return gqClient.mutate({
      mutation: reviewerRereviewMutation,
      variables: {
        userId: convertToGraphQLId(TYPENAME_USER, `${userId}`),
        projectPath: this.fullPath,
        iid: this.iid.toString(),
      },
    });
  }
}
