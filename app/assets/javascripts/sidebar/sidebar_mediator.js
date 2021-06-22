import Store from 'ee_else_ce/sidebar/stores/sidebar_store';
import createFlash from '~/flash';
import { __ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import { visitUrl } from '../lib/utils/url_utility';
import Service from './services/sidebar_service';

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
      fullPath: options.fullPath,
      iid: options.iid,
      issuableType: options.issuableType,
    });
    SidebarMediator.singleton = this;
  }

  assignYourself() {
    this.store.addAssignee(this.store.currentUser);
  }

  saveAssignees(field) {
    const selected = this.store.assignees.map((u) => u.id);

    // If there are no ids, that means we have to unassign (which is id = 0)
    // And it only accepts an array, hence [0]
    const assignees = selected.length === 0 ? [0] : selected;
    const data = { assignee_ids: assignees };

    return this.service.update(field, data);
  }

  saveReviewers(field) {
    const selected = this.store.reviewers.map((u) => u.id);

    // If there are no ids, that means we have to unassign (which is id = 0)
    // And it only accepts an array, hence [0]
    const reviewers = selected.length === 0 ? [0] : selected;
    const data = { reviewer_ids: reviewers };

    return this.service.update(field, data);
  }

  requestReview({ userId, callback }) {
    return this.service
      .requestReview(userId)
      .then(() => {
        this.store.updateReviewer(userId);
        toast(__('Requested review'));
        callback(userId, true);
      })
      .catch(() => callback(userId, false));
  }

  setMoveToProjectId(projectId) {
    this.store.setMoveToProjectId(projectId);
  }

  fetch() {
    return this.service
      .get()
      .then(([restResponse, graphQlResponse]) => {
        this.processFetchedData(restResponse.data, graphQlResponse.data);
      })
      .catch(() =>
        createFlash({
          message: __('Error occurred when fetching sidebar data'),
        }),
      );
  }

  processFetchedData(data) {
    this.store.setAssigneeData(data);
    this.store.setReviewerData(data);
    this.store.setTimeTrackingData(data);
    this.store.setParticipantsData(data);
    this.store.setSubscriptionsData(data);
  }

  toggleSubscription() {
    this.store.setFetchingState('subscriptions', true);
    return this.service
      .toggleSubscription()
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
    return this.service.getProjectsAutocomplete(searchTerm).then(({ data }) => {
      this.store.setAutocompleteProjects(data);
      return this.store.autocompleteProjects;
    });
  }

  moveIssue() {
    return this.service.moveIssue(this.store.moveToProjectId).then(({ data }) => {
      if (window.location.pathname !== data.web_url) {
        visitUrl(data.web_url);
      }
    });
  }
}
