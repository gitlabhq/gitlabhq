export default class SidebarStore {
  constructor(options) {
    if (!SidebarStore.singleton) {
      this.initSingleton(options);
    }

    // eslint-disable-next-line no-constructor-return
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
    this.addingAssignees = [];
    this.reviewers = [];
    this.addingReviewers = [];
    this.isFetching = {
      assignees: true,
      reviewers: true,
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
    this.issuableType = options.issuableType;

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

      if (assignee.id !== this.currentUser.id) {
        this.addingAssignees.push(assignee.id);
      }
    }
  }

  addReviewer(reviewer) {
    if (!this.findReviewer(reviewer)) {
      this.reviewers.push(reviewer);

      if (reviewer.id !== this.currentUser.id) {
        this.addingReviewers.push(reviewer.id);
      }
    }
  }

  updateAssignee(id, stateKey) {
    const assignee = this.findAssignee({ id });

    if (assignee) {
      assignee[stateKey] = !assignee[stateKey];
    }
  }

  updateReviewer(id, stateKey) {
    const reviewer = this.findReviewer({ id });

    if (reviewer) {
      reviewer[stateKey] = !reviewer[stateKey];
    }
  }

  overwrite(key, newData) {
    this[key] = newData;
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
      this.addingAssignees = this.addingAssignees.filter(({ id }) => id !== assignee.id);
    }
  }

  removeReviewer(reviewer) {
    if (reviewer) {
      this.reviewers = this.reviewers.filter(({ id }) => id !== reviewer.id);
      this.addingReviewers = this.addingReviewers.filter(({ id }) => id !== reviewer.id);
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

  get currentUserHasAttention() {
    if (!window.gon?.features?.mrAttentionRequests || !this.isMergeRequest) return false;

    const currentUserId = this.currentUser.id;
    const currentUserReviewer = this.findReviewer({ id: currentUserId });
    const currentUserAssignee = this.findAssignee({ id: currentUserId });

    return currentUserReviewer?.attention_requested || currentUserAssignee?.attention_requested;
  }

  get isAddingAssignee() {
    return this.addingAssignees.length > 0;
  }

  get isAddingReviewer() {
    return this.addingReviewers.length > 0;
  }

  get isMergeRequest() {
    return this.issuableType === 'merge_request';
  }
}
