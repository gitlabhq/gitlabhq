export default class SidebarStore {
  constructor(store) {
    if (!SidebarStore.singleton) {
      const { currentUser, rootPath, editable } = store;
      this.currentUser = currentUser;
      this.rootPath = rootPath;
      this.editable = editable;
      this.timeEstimate = 0;
      this.totalTimeSpent = 0;
      this.humanTimeEstimate = '';
      this.humanTimeSpent = '';
      this.assignees = [];

      SidebarStore.singleton = this;
    }

    return SidebarStore.singleton;
  }

  processAssigneeData(data) {
    if (data.assignees) {
      this.assignees = data.assignees;
    }
  }

  processTimeTrackingData(data) {
    this.timeEstimate = data.time_estimate;
    this.totalTimeSpent = data.total_time_spent;
    this.humanTimeEstimate = data.human_time_estimate;
    this.humanTimeSpent = data.human_time_spent;
  }

  addAssignee(assignee) {
    if (!this.findAssignee(assignee)) {
      this.assignees.push(assignee);
    }
  }

  findAssignee(findAssignee) {
    return this.assignees.filter(assignee => assignee.id === findAssignee.id)[0];
  }

  removeAssignee(removeAssignee) {
    if (removeAssignee) {
      this.assignees = this.assignees.filter(assignee => assignee.id !== removeAssignee.id);
    }
  }

  removeAllAssignees() {
    this.assignees = [];
  }
}
