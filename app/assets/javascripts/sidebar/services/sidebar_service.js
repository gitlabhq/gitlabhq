import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

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
    return Vue.http.get(this.endpoint);
  }

  update(key, data) {
    return Vue.http.put(this.endpoint, {
      [key]: data,
    }, {
      emulateJSON: true,
    });
  }

  getProjectsAutocomplete(searchTerm) {
    return Vue.http.get(this.projectsAutocompleteEndpoint, {
      params: {
        search: searchTerm,
      },
    });
  }

  toggleSubscription() {
    return Vue.http.post(this.toggleSubscriptionEndpoint);
  }

  moveIssue(moveToProjectId) {
    return Vue.http.post(this.moveIssueEndpoint, {
      move_to_project_id: moveToProjectId,
    });
  }
}
