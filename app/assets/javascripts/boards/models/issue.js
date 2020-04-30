/* eslint-disable no-unused-vars */
/* global ListLabel */
/* global ListMilestone */
/* global ListAssignee */

import axios from '~/lib/utils/axios_utils';
import './label';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import IssueProject from './project';
import boardsStore from '../stores/boards_store';

class ListIssue {
  constructor(obj) {
    this.subscribed = obj.subscribed;
    this.labels = [];
    this.assignees = [];
    this.selected = false;
    this.position = obj.position || obj.relative_position || Infinity;
    this.isFetching = {
      subscriptions: true,
    };
    this.closed = obj.closed;
    this.isLoading = {};

    this.refreshData(obj);
  }

  refreshData(obj) {
    boardsStore.refreshIssueData(this, obj);
  }

  addLabel(label) {
    if (!this.findLabel(label)) {
      this.labels.push(new ListLabel(label));
    }
  }

  findLabel(findLabel) {
    return this.labels.find(label => label.id === findLabel.id);
  }

  removeLabel(removeLabel) {
    if (removeLabel) {
      this.labels = this.labels.filter(label => removeLabel.id !== label.id);
    }
  }

  removeLabels(labels) {
    labels.forEach(this.removeLabel.bind(this));
  }

  addAssignee(assignee) {
    if (!this.findAssignee(assignee)) {
      this.assignees.push(new ListAssignee(assignee));
    }
  }

  findAssignee(findAssignee) {
    return this.assignees.find(assignee => assignee.id === findAssignee.id);
  }

  removeAssignee(removeAssignee) {
    if (removeAssignee) {
      this.assignees = this.assignees.filter(assignee => assignee.id !== removeAssignee.id);
    }
  }

  removeAllAssignees() {
    this.assignees = [];
  }

  addMilestone(milestone) {
    const miletoneId = this.milestone ? this.milestone.id : null;
    if (IS_EE && milestone.id !== miletoneId) {
      this.milestone = new ListMilestone(milestone);
    }
  }

  removeMilestone(removeMilestone) {
    if (IS_EE && removeMilestone && removeMilestone.id === this.milestone.id) {
      this.milestone = {};
    }
  }

  getLists() {
    return boardsStore.state.lists.filter(list => list.findIssue(this.id));
  }

  updateData(newData) {
    Object.assign(this, newData);
  }

  setFetchingState(key, value) {
    this.isFetching[key] = value;
  }

  setLoadingState(key, value) {
    this.isLoading[key] = value;
  }

  update() {
    return boardsStore.updateIssue(this);
  }
}

window.ListIssue = ListIssue;

export default ListIssue;
