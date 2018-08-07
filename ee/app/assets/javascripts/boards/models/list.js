/* eslint-disable no-param-reassign */
import List from '~/boards/models/list';
import ListAssignee from '~/vue_shared/models/assignee';
import ListMilestone from '~/boards/models/milestone';

const EE_TYPES = {
  promotion: {
    isPreset: true,
    isExpandable: false,
    isBlank: true,
  },
};

class ListEE extends List {
  constructor(...args) {
    super(...args);
    this.totalWeight = 0;
  }

  getTypeInfo(type) {
    return EE_TYPES[type] || super.getTypeInfo(type);
  }

  getIssues(...args) {
    return super.getIssues(...args).then(data => {
      this.totalWeight = data.total_weight;
    });
  }

  addIssue(issue, ...args) {
    super.addIssue(issue, ...args);

    if (issue.weight) {
      this.totalWeight += issue.weight;
    }
  }

  removeIssue(issue, ...args) {
    if (issue.weight) {
      this.totalWeight -= issue.weight;
    }

    super.removeIssue(issue, ...args);
  }

  addWeight(weight) {
    this.totalWeight += weight;
  }

  onNewIssueResponse(issue, data) {
    issue.milestone = data.milestone ? new ListMilestone(data.milestone) : data.milestone;
    issue.assignees = Array.isArray(data.assignees)
      ? data.assignees.map(assignee => new ListAssignee(assignee))
      : data.assignees;
    issue.labels = data.labels;

    super.onNewIssueResponse(issue, data);
  }
}

window.List = ListEE;

export default ListEE;
