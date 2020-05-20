/* eslint-disable no-underscore-dangle, class-methods-use-this, consistent-return */

import ListIssue from 'ee_else_ce/boards/models/issue';
import { __ } from '~/locale';
import ListLabel from './label';
import ListAssignee from './assignee';
import flash from '~/flash';
import boardsStore from '../stores/boards_store';
import ListMilestone from './milestone';

const PER_PAGE = 20;

const TYPES = {
  backlog: {
    isPreset: true,
    isExpandable: true,
    isBlank: false,
  },
  closed: {
    isPreset: true,
    isExpandable: true,
    isBlank: false,
  },
  blank: {
    isPreset: true,
    isExpandable: false,
    isBlank: true,
  },
  default: {
    // includes label, assignee, and milestone lists
    isPreset: false,
    isExpandable: true,
    isBlank: false,
  },
};

class List {
  constructor(obj) {
    this.id = obj.id;
    this._uid = this.guid();
    this.position = obj.position;
    this.title = (obj.list_type || obj.listType) === 'backlog' ? __('Open') : obj.title;
    this.type = obj.list_type || obj.listType;

    const typeInfo = this.getTypeInfo(this.type);
    this.preset = Boolean(typeInfo.isPreset);
    this.isExpandable = Boolean(typeInfo.isExpandable);
    this.isExpanded = !obj.collapsed;
    this.page = 1;
    this.loading = true;
    this.loadingMore = false;
    this.issues = obj.issues || [];
    this.issuesSize = obj.issuesSize ? obj.issuesSize : 0;
    this.maxIssueCount = obj.maxIssueCount || obj.max_issue_count || 0;

    if (obj.label) {
      this.label = new ListLabel(obj.label);
    } else if (obj.user || obj.assignee) {
      this.assignee = new ListAssignee(obj.user || obj.assignee);
      this.title = this.assignee.name;
    } else if (IS_EE && obj.milestone) {
      this.milestone = new ListMilestone(obj.milestone);
      this.title = this.milestone.title;
    }

    if (!typeInfo.isBlank && this.id) {
      this.getIssues().catch(() => {
        // TODO: handle request error
      });
    }
  }

  guid() {
    const s4 = () =>
      Math.floor((1 + Math.random()) * 0x10000)
        .toString(16)
        .substring(1);
    return `${s4()}${s4()}-${s4()}-${s4()}-${s4()}-${s4()}${s4()}${s4()}`;
  }

  save() {
    return boardsStore.saveList(this);
  }

  destroy() {
    const index = boardsStore.state.lists.indexOf(this);
    boardsStore.state.lists.splice(index, 1);
    boardsStore.updateNewListDropdown(this.id);

    boardsStore.destroyList(this.id).catch(() => {
      // TODO: handle request error
    });
  }

  update() {
    const collapsed = !this.isExpanded;
    return boardsStore.updateList(this.id, this.position, collapsed).catch(() => {
      // TODO: handle request error
    });
  }

  nextPage() {
    if (this.issuesSize > this.issues.length) {
      if (this.issues.length / PER_PAGE >= 1) {
        this.page += 1;
      }

      return this.getIssues(false);
    }
  }

  getIssues(emptyIssues = true) {
    return boardsStore.getListIssues(this, emptyIssues);
  }

  newIssue(issue) {
    this.addIssue(issue, null, 0);
    this.issuesSize += 1;

    return boardsStore
      .newIssue(this.id, issue)
      .then(res => res.data)
      .then(data => this.onNewIssueResponse(issue, data));
  }

  createIssues(data) {
    data.forEach(issueObj => {
      this.addIssue(new ListIssue(issueObj));
    });
  }

  addMultipleIssues(issues, listFrom, newIndex) {
    boardsStore.addMultipleListIssues(this, issues, listFrom, newIndex);
  }

  addIssue(issue, listFrom, newIndex) {
    boardsStore.addListIssue(this, issue, listFrom, newIndex);
  }

  moveIssue(issue, oldIndex, newIndex, moveBeforeId, moveAfterId) {
    this.issues.splice(oldIndex, 1);
    this.issues.splice(newIndex, 0, issue);

    boardsStore.moveIssue(issue.id, null, null, moveBeforeId, moveAfterId).catch(() => {
      // TODO: handle request error
    });
  }

  moveMultipleIssues({ issues, oldIndicies, newIndex, moveBeforeId, moveAfterId }) {
    oldIndicies.reverse().forEach(index => {
      this.issues.splice(index, 1);
    });
    this.issues.splice(newIndex, 0, ...issues);

    boardsStore
      .moveMultipleIssues({
        ids: issues.map(issue => issue.id),
        fromListId: null,
        toListId: null,
        moveBeforeId,
        moveAfterId,
      })
      .catch(() => flash(__('Something went wrong while moving issues.')));
  }

  updateIssueLabel(issue, listFrom, moveBeforeId, moveAfterId) {
    boardsStore.moveIssue(issue.id, listFrom.id, this.id, moveBeforeId, moveAfterId).catch(() => {
      // TODO: handle request error
    });
  }

  updateMultipleIssues(issues, listFrom, moveBeforeId, moveAfterId) {
    boardsStore
      .moveMultipleIssues({
        ids: issues.map(issue => issue.id),
        fromListId: listFrom.id,
        toListId: this.id,
        moveBeforeId,
        moveAfterId,
      })
      .catch(() => flash(__('Something went wrong while moving issues.')));
  }

  findIssue(id) {
    return this.issues.find(issue => issue.id === id);
  }

  removeMultipleIssues(removeIssues) {
    const ids = removeIssues.map(issue => issue.id);

    this.issues = this.issues.filter(issue => {
      const matchesRemove = ids.includes(issue.id);

      if (matchesRemove) {
        this.issuesSize -= 1;
        issue.removeLabel(this.label);
      }

      return !matchesRemove;
    });
  }

  removeIssue(removeIssue) {
    this.issues = this.issues.filter(issue => {
      const matchesRemove = removeIssue.id === issue.id;

      if (matchesRemove) {
        this.issuesSize -= 1;
        issue.removeLabel(this.label);
      }

      return !matchesRemove;
    });
  }

  getTypeInfo(type) {
    return TYPES[type] || TYPES.default;
  }

  onNewIssueResponse(issue, data) {
    issue.refreshData(data);

    if (this.issuesSize > 1) {
      const moveBeforeId = this.issues[1].id;
      boardsStore.moveIssue(issue.id, null, null, null, moveBeforeId);
    }
  }
}

window.List = List;

export default List;
