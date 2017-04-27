/* eslint-disable no-unused-vars, space-before-function-paren, arrow-body-style, arrow-parens, comma-dangle, max-len */
/* global ListLabel */
/* global ListMilestone */
/* global ListUser */

import Vue from 'vue';

class ListIssue {
  constructor (obj) {
    this.globalId = obj.id;
    this.id = obj.iid;
    this.title = obj.title;
    this.confidential = obj.confidential;
    this.dueDate = obj.due_date;
    this.subscribed = obj.subscribed;
    this.labels = [];
    this.assignees = [];
    this.selectedAssigneeIds = [];
    this.selected = false;
    this.position = obj.relative_position || Infinity;
    this.milestone_id = obj.milestone_id;

    if (obj.milestone) {
      this.milestone = new ListMilestone(obj.milestone);
    }

    obj.labels.forEach((label) => {
      this.labels.push(new ListLabel(label));
    });

    this.processAssignees(obj.assignees);
  }

  processAssignees(assignees) {
    this.assignees = assignees.map(a => new ListUser(a));
    this.selectedAssigneeIds = this.assignees.map(a => a.id);
  }

  addLabel (label) {
    if (!this.findLabel(label)) {
      this.labels.push(new ListLabel(label));
    }
  }

  findLabel (findLabel) {
    return this.labels.filter(label => label.title === findLabel.title)[0];
  }

  removeLabel (removeLabel) {
    if (removeLabel) {
      this.labels = this.labels.filter(label => removeLabel.title !== label.title);
    }
  }

  removeLabels (labels) {
    labels.forEach(this.removeLabel.bind(this));
  }

  addUserId (id) {
    if (this.selectedAssigneeIds.indexOf(id) === -1) {
      this.selectedAssigneeIds.push(id);
    }
  }

  removeUserId (id) {
    this.selectedAssigneeIds = this.selectedAssigneeIds.filter(uid => uid !== id);
  }

  removeAllUserIds () {
    this.selectedAssigneeIds = [];
  }

  getLists () {
    return gl.issueBoards.BoardsStore.state.lists.filter(list => list.findIssue(this.id));
  }

  update (url) {
    const data = {
      issue: {
        milestone_id: this.milestone ? this.milestone.id : null,
        due_date: this.dueDate,
        assignee_ids: this.selectedAssigneeIds.length > 0 ? this.selectedAssigneeIds : [0],
        label_ids: this.labels.map((label) => label.id)
      }
    };

    if (!data.issue.label_ids.length) {
      data.issue.label_ids = [''];
    }

    return Vue.http.patch(url, data);
  }
}

window.ListIssue = ListIssue;
