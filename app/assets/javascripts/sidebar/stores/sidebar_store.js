export default class SidebarStore {
  constructor(options) {
    if (!SidebarStore.singleton) {
      this.initSingleton(options);
    }

    return SidebarStore.singleton;
  }

  initSingleton(options) {
    const { currentUser, rootPath, editable, timeTrackingLimitToHours } = options;
    this.currentUser = currentUser;
    this.rootPath = rootPath;
    this.editable = editable;
    this.timeEstimate = 0;
    this.totalTimeSpent = 0;
    this.humanTimeEstimate = '';
    this.humanTimeSpent = '';
    this.timeTrackingLimitToHours = timeTrackingLimitToHours;
    this.assignees = [];
    this.reviewers = [];
    this.isFetching = {
      assignees: true,
      reviewers: true,
      participants: true,
      subscriptions: true,
    };
    this.isLoading = {};
    this.autocompleteProjects = [];
    this.moveToProjectId = 0;
    this.isLockDialogOpen = false;
    this.participants = [];
    this.projectEmailsDisabled = false;
    this.subscribeDisabledDescription = '';
    this.subscribed = null;
    this.changing = false;

    SidebarStore.singleton = this;
  }

  setAssigneeData({ assignees }) {
    this.isFetching.assignees = false;
    if (assignees) {
      this.assignees = assignees;
    }
  }

  setReviewerData({ reviewers }) {
    this.isFetching.reviewers = false;
    if (reviewers) {
      this.reviewers = reviewers;
    }
  }

  resetChanging() {
    this.changing = false;
  }

  setTimeTrackingData(data) {
    this.timeEstimate = data.time_estimate;
    this.totalTimeSpent = data.total_time_spent;
    this.humanTimeEstimate = data.human_time_estimate;
    this.humanTotalTimeSpent = data.human_total_time_spent;
  }

  setParticipantsData(data) {
    this.isFetching.participants = false;
    this.participants = data.participants || [];
  }

  setSubscriptionsData(data) {
    this.projectEmailsDisabled = data.project_emails_disabled || false;
    this.subscribeDisabledDescription = data.subscribe_disabled_description;
    this.isFetching.subscriptions = false;
    this.subscribed = data.subscribed || false;
  }

  setFetchingState(key, value) {
    this.isFetching[key] = value;
  }

  setLoadingState(key, value) {
    this.isLoading[key] = value;
  }

  addAssignee(assignee) {
    if (!this.findAssignee(assignee)) {
      this.changing = true;
      this.assignees.push(assignee);
    }
  }

  addReviewer(reviewer) {
    if (!this.findReviewer(reviewer)) {
      this.reviewers.push(reviewer);
    }
  }

  findAssignee(findAssignee) {
    return this.assignees.find(({ id }) => id === findAssignee.id);
  }

  findReviewer(findReviewer) {
    return this.reviewers.find(({ id }) => id === findReviewer.id);
  }

  removeAssignee(assignee) {
    if (assignee) {
      this.changing = true;
      this.assignees = this.assignees.filter(({ id }) => id !== assignee.id);
    }
  }

  removeReviewer(reviewer) {
    if (reviewer) {
      this.reviewers = this.reviewers.filter(({ id }) => id !== reviewer.id);
    }
  }

  removeAllAssignees() {
    this.changing = true;
    this.assignees = [];
  }

  removeAllReviewers() {
    this.reviewers = [];
  }

  setAssigneesFromRealtime(data) {
    this.assignees = data;
  }

  setAutocompleteProjects(projects) {
    this.autocompleteProjects = projects;
  }

  setSubscribedState(subscribed) {
    this.subscribed = subscribed;
  }

  setMoveToProjectId(moveToProjectId) {
    this.moveToProjectId = moveToProjectId;
  }
}
