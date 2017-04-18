export default {
  timeEstimate: 0,
  totalTimeSpent: 0,
  humanTimeEstimate: '',
  humanTimeSpent: '',
  selectedUserIds: [],
  renderedUsers: [],

  init(store) {
    const { currentUserId, rootPath, editable } = store;
    this.currentUserId = currentUserId;
    this.rootPath = rootPath;
    this.editable = editable;
  },

  processUserData(data) {
    this.renderedUsers = data.assignees;

    this.removeAllUserIds();
    this.renderedUsers.map(u => this.addUserId(u.id));
  },
  processTimeTrackingData(data) {
    this.timeEstimate = data.time_estimate;
    this.totalTimeSpent = data.total_time_spent;
    this.humanTimeEstimate = data.human_time_estimate;
    this.humanTimeSpent = data.human_time_spent;
  },

  addUserId(id) {
    // Prevent duplicate user id's from being added
    if (this.selectedUserIds.indexOf(id) === -1) {
      this.selectedUserIds.push(id);
    }
  },
  removeUserId(id) {
    this.selectedUserIds = this.selectedUserIds.filter(uid => uid !== id);
  },
  removeAllUserIds() {
    this.selectedUserIds = [];
  }
};
