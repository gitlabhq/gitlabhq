/* eslint-disable no-unused-vars, space-before-function-paren, arrow-body-style, arrow-parens, comma-dangle, max-len */
/* global ListLabel */
/* global ListMilestone */
/* global ListAssignee */

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
    this.selected = false;
    this.position = obj.relative_position || Infinity;
    this.milestone_id = obj.milestone_id;

    if (obj.milestone) {
      this.milestone = new ListMilestone(obj.milestone);
    }

    obj.labels.forEach((label) => {
      this.labels.push(new ListLabel(label));
    });

    this.assignees = obj.assignees.map(a => new ListAssignee(a));
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

  addAssignee (assignee) {
    if (!this.findAssignee(assignee)) {
      this.assignees.push(new ListAssignee(assignee));
    }
  }

  findAssignee (findAssignee) {
    return this.assignees.filter(assignee => assignee.id === findAssignee.id)[0];
  }

  removeAssignee (removeAssignee) {
    if (removeAssignee) {
      this.assignees = this.assignees.filter(assignee => assignee.id !== removeAssignee.id);
    }
  }

  removeAllAssignees () {
    this.assignees = [];
  }

  getLists () {
    return gl.issueBoards.BoardsStore.state.lists.filter(list => list.findIssue(this.id));
  }

  update (url) {
    const data = {
      issue: {
        milestone_id: this.milestone ? this.milestone.id : null,
        due_date: this.dueDate,
        assignee_ids: this.assignees.length > 0 ? this.assignees.map((u) => u.id) : [0],
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
