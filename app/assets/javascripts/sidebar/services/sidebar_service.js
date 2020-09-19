import sidebarDetailsQuery from 'ee_else_ce/sidebar/queries/sidebarDetails.query.graphql';
import axios from '~/lib/utils/axios_utils';
import createGqClient, { fetchPolicies } from '~/lib/graphql';

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

      SidebarService.singleton = this;
    }

    return SidebarService.singleton;
  }

  get() {
    return Promise.all([
      axios.get(this.endpoint),
      gqClient.query({
        query: sidebarDetailsQuery,
        variables: {
          fullPath: this.fullPath,
          iid: this.iid.toString(),
        },
      }),
    ]);
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
}
