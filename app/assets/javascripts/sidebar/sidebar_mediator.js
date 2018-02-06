import { visitUrl } from '../lib/utils/url_utility';
import Flash from '../flash';
import Service from './services/sidebar_service';
import Store from './stores/sidebar_store';

export default class SidebarMediator {
  constructor(options) {
    if (!SidebarMediator.singleton) {
      this.initSingleton(options);
    }
    return SidebarMediator.singleton;
  }

  initSingleton(options) {
    this.store = new Store(options);
    this.service = new Service({
      endpoint: options.endpoint,
      toggleSubscriptionEndpoint: options.toggleSubscriptionEndpoint,
      moveIssueEndpoint: options.moveIssueEndpoint,
      projectsAutocompleteEndpoint: options.projectsAutocompleteEndpoint,
    });
    SidebarMediator.singleton = this;
  }

  assignYourself() {
    this.store.addAssignee(this.store.currentUser);
  }

  saveAssignees(field) {
    const selected = this.store.assignees.map(u => u.id);

    // If there are no ids, that means we have to unassign (which is id = 0)
    // And it only accepts an array, hence [0]
    return this.service.update(field, selected.length === 0 ? [0] : selected);
  }

  setMoveToProjectId(projectId) {
    this.store.setMoveToProjectId(projectId);
  }

  fetch() {
    return this.service.get()
      .then(response => response.json())
      .then((data) => {
        this.processFetchedData(data);
      })
      .catch(() => new Flash('Error occurred when fetching sidebar data'));
  }

  processFetchedData(data) {
    this.store.setAssigneeData(data);
    this.store.setTimeTrackingData(data);
    this.store.setParticipantsData(data);
    this.store.setSubscriptionsData(data);
  }

  toggleSubscription() {
    this.store.setFetchingState('subscriptions', true);
    return this.service.toggleSubscription()
      .then(() => {
        this.store.setSubscribedState(!this.store.subscribed);
        this.store.setFetchingState('subscriptions', false);
      })
      .catch((err) => {
        this.store.setFetchingState('subscriptions', false);
        throw err;
      });
  }

  fetchAutocompleteProjects(searchTerm) {
    return this.service.getProjectsAutocomplete(searchTerm)
      .then(response => response.json())
      .then((data) => {
        this.store.setAutocompleteProjects(data);
        return this.store.autocompleteProjects;
      });
  }

  moveIssue() {
    return this.service.moveIssue(this.store.moveToProjectId)
      .then(response => response.json())
      .then((data) => {
        if (location.pathname !== data.web_url) {
          visitUrl(data.web_url);
        }
      });
  }
}
