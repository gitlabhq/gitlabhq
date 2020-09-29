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

    SidebarStore.singleton = this;
  }

  setAssigneeData(data) {
    this.isFetching.assignees = false;
    if (data.assignees) {
      this.assignees = data.assignees;
    }
  }

  setReviewerData(data) {
    this.isFetching.reviewers = false;
    if (data.reviewers) {
      this.reviewers = data.reviewers;
    }
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
      this.assignees.push(assignee);
    }
  }

  addReviewer(reviewer) {
    if (!this.findReviewer(reviewer)) {
      this.reviewers.push(reviewer);
    }
  }

  findAssignee(findAssignee) {
    return this.assignees.find(assignee => assignee.id === findAssignee.id);
  }

  findReviewer(findReviewer) {
    return this.reviewers.find(reviewer => reviewer.id === findReviewer.id);
  }

  removeAssignee(removeAssignee) {
    if (removeAssignee) {
      this.assignees = this.assignees.filter(assignee => assignee.id !== removeAssignee.id);
    }
  }

  removeReviewer(removeReviewer) {
    if (removeReviewer) {
      this.reviewers = this.reviewers.filter(reviewer => reviewer.id !== removeReviewer.id);
    }
  }

  removeAllAssignees() {
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
