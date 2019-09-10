import axios from '~/lib/utils/axios_utils';

export default class SidebarService {
  constructor(endpointMap) {
    if (!SidebarService.singleton) {
      this.endpoint = endpointMap.endpoint;
      this.toggleSubscriptionEndpoint = endpointMap.toggleSubscriptionEndpoint;
      this.moveIssueEndpoint = endpointMap.moveIssueEndpoint;
      this.projectsAutocompleteEndpoint = endpointMap.projectsAutocompleteEndpoint;

      SidebarService.singleton = this;
    }

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

  toggleSubscription() {
    return axios.post(this.toggleSubscriptionEndpoint);
  }

  moveIssue(moveToProjectId) {
    return axios.post(this.moveIssueEndpoint, {
      move_to_project_id: moveToProjectId,
    });
  }
}
