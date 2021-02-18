/* eslint-disable no-unused-vars */
/* global ListLabel */
/* global ListMilestone */
/* global ListAssignee */

import axios from '~/lib/utils/axios_utils';
import './label';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import boardsStore from '../stores/boards_store';
import IssueProject from './project';

class ListIssue {
  constructor(obj) {
    this.subscribed = obj.subscribed;
    this.labels = [];
    this.assignees = [];
    this.selected = false;
    this.position = obj.position || obj.relative_position || obj.relativePosition || Infinity;
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
    boardsStore.addIssueLabel(this, label);
  }

  findLabel(findLabel) {
    return boardsStore.findIssueLabel(this, findLabel);
  }

  removeLabel(removeLabel) {
    boardsStore.removeIssueLabel(this, removeLabel);
  }

  removeLabels(labels) {
    boardsStore.removeIssueLabels(this, labels);
  }

  addAssignee(assignee) {
    boardsStore.addIssueAssignee(this, assignee);
  }

  findAssignee(findAssignee) {
    return boardsStore.findIssueAssignee(this, findAssignee);
  }

  setAssignees(assignees) {
    boardsStore.setIssueAssignees(this, assignees);
  }

  removeAssignee(removeAssignee) {
    boardsStore.removeIssueAssignee(this, removeAssignee);
  }

  removeAllAssignees() {
    boardsStore.removeAllIssueAssignees(this);
  }

  addMilestone(milestone) {
    boardsStore.addIssueMilestone(this, milestone);
  }

  removeMilestone(removeMilestone) {
    boardsStore.removeIssueMilestone(this, removeMilestone);
  }

  getLists() {
    return boardsStore.state.lists.filter((list) => list.findIssue(this.id));
  }

  updateData(newData) {
    boardsStore.updateIssueData(this, newData);
  }

  setFetchingState(key, value) {
    boardsStore.setIssueFetchingState(this, key, value);
  }

  setLoadingState(key, value) {
    boardsStore.setIssueLoadingState(this, key, value);
  }

  update() {
    return boardsStore.updateIssue(this);
  }
}

window.ListIssue = ListIssue;

export default ListIssue;
