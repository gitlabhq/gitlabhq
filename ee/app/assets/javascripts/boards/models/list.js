/* eslint-disable no-param-reassign */
import List from '~/boards/models/list';
import ListAssignee from '~/vue_shared/models/assignee';

const EE_TYPES = {
  promotion: {
    isPreset: true,
    isExpandable: false,
    isBlank: true,
  },
};

class ListEE extends List {
  getTypeInfo(type) {
    return EE_TYPES[type] || super.getTypeInfo(type);
  }

  onNewIssueResponse(issue, data) {
    issue.milestone = data.milestone;
    issue.assignees = Array.isArray(data.assignees)
      ? data.assignees.map(assignee => new ListAssignee(assignee))
      : data.assignees;
    issue.labels = data.labels;

    super.onNewIssueResponse(issue, data);
  }
}

window.List = ListEE;

export default ListEE;
