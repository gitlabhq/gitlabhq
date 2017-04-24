export default class SidebarStore {
  constructor(store) {
    if (!SidebarStore.singleton) {
      const { currentUserId, rootPath, editable } = store;
      this.currentUserId = currentUserId;
      this.rootPath = rootPath;
      this.editable = editable;
      this.timeEstimate = 0;
      this.totalTimeSpent = 0;
      this.humanTimeEstimate = '';
      this.humanTimeSpent = '';
      this.selectedUserIds = [];
      this.renderedUsers = [];

      SidebarStore.singleton = this;
    }

    return SidebarStore.singleton;
  }

  processUserData(data) {
    this.renderedUsers = data.assignees;

    this.removeAllUserIds();
    this.renderedUsers.map(u => this.addUserId(u.id));
  }

  processTimeTrackingData(data) {
    this.timeEstimate = data.time_estimate;
    this.totalTimeSpent = data.total_time_spent;
    this.humanTimeEstimate = data.human_time_estimate;
    this.humanTimeSpent = data.human_time_spent;
  }

  addUserId(id) {
    // Prevent duplicate user id's from being added
    if (this.selectedUserIds.indexOf(id) === -1) {
      this.selectedUserIds.push(id);
    }
  }

  removeUserId(id) {
    this.selectedUserIds = this.selectedUserIds.filter(uid => uid !== id);
  }

  removeAllUserIds() {
    this.selectedUserIds = [];
  }
}
