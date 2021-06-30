import sidebarDetailsIssueQuery from 'ee_else_ce/sidebar/queries/sidebarDetails.query.graphql';
import { TYPE_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import createGqClient, { fetchPolicies } from '~/lib/graphql';
import axios from '~/lib/utils/axios_utils';
import reviewerRereviewMutation from '../queries/reviewer_rereview.mutation.graphql';
import sidebarDetailsMRQuery from '../queries/sidebarDetailsMR.query.graphql';

const queries = {
  merge_request: sidebarDetailsMRQuery,
  issue: sidebarDetailsIssueQuery,
};

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
      this.toggleSubscriptionEndpoint = endpointMap.toggleSubscriptionEndpoint;
      this.moveIssueEndpoint = endpointMap.moveIssueEndpoint;
      this.projectsAutocompleteEndpoint = endpointMap.projectsAutocompleteEndpoint;
      this.fullPath = endpointMap.fullPath;
      this.iid = endpointMap.iid;
      this.issuableType = endpointMap.issuableType;

      SidebarService.singleton = this;
    }

    return SidebarService.singleton;
  }

  get() {
    return Promise.all([
      axios.get(this.endpoint),
      gqClient.query({
        query: this.sidebarDetailsQuery(),
        variables: {
          fullPath: this.fullPath,
          iid: this.iid.toString(),
        },
      }),
    ]);
  }

  sidebarDetailsQuery() {
    return queries[this.issuableType];
  }

  update(key, data) {
    return axios.put(this.endpoint, { [key]: data });
  }

  updateWithGraphQl(mutation, variables) {
    return gqClient.mutate({
      mutation,
      variables: {
        ...variables,
        projectPath: this.fullPath,
        iid: this.iid.toString(),
      },
    });
  }

  getProjectsAutocomplete(searchTerm) {
    return axios.get(this.projectsAutocompleteEndpoint, {
      params: {
        search: searchTerm,
      },
    });
  }

  toggleSubscription() {
    return axios.post(this.toggleSubscriptionEndpoint);
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
        userId: convertToGraphQLId(TYPE_USER, `${userId}`),
        projectPath: this.fullPath,
        iid: this.iid.toString(),
      },
    });
  }
}
