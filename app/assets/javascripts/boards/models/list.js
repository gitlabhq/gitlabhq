/* eslint-disable no-underscore-dangle, class-methods-use-this, consistent-return, no-shadow */

import ListIssue from 'ee_else_ce/boards/models/issue';
import { __ } from '~/locale';
import ListLabel from './label';
import ListAssignee from './assignee';
import { urlParamsToObject } from '~/lib/utils/common_utils';
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
  constructor(obj, defaultAvatar) {
    this.id = obj.id;
    this._uid = this.guid();
    this.position = obj.position;
    this.title = obj.list_type === 'backlog' ? __('Open') : obj.title;
    this.type = obj.list_type;

    const typeInfo = this.getTypeInfo(this.type);
    this.preset = Boolean(typeInfo.isPreset);
    this.isExpandable = Boolean(typeInfo.isExpandable);
    this.isExpanded = !obj.collapsed;
    this.page = 1;
    this.loading = true;
    this.loadingMore = false;
    this.issues = obj.issues || [];
    this.issuesSize = obj.issuesSize ? obj.issuesSize : 0;
    this.maxIssueCount = Object.hasOwnProperty.call(obj, 'max_issue_count')
      ? obj.max_issue_count
      : 0;
    this.defaultAvatar = defaultAvatar;

    if (obj.label) {
      this.label = new ListLabel(obj.label);
    } else if (obj.user) {
      this.assignee = new ListAssignee(obj.user);
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
    const entity = this.label || this.assignee || this.milestone;
    let entityType = '';
    if (this.label) {
      entityType = 'label_id';
    } else if (this.assignee) {
      entityType = 'assignee_id';
    } else if (IS_EE && this.milestone) {
      entityType = 'milestone_id';
    }

    return boardsStore
      .createList(entity.id, entityType)
      .then(res => res.data)
      .then(data => {
        this.id = data.id;
        this.type = data.list_type;
        this.position = data.position;
        this.label = data.label;

        return this.getIssues();
      });
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
    const data = {
      ...urlParamsToObject(boardsStore.filter.path),
      page: this.page,
    };

    if (this.label && data.label_name) {
      data.label_name = data.label_name.filter(label => label !== this.label.title);
    }

    if (emptyIssues) {
      this.loading = true;
    }

    return boardsStore
      .getIssuesForList(this.id, data)
      .then(res => res.data)
      .then(data => {
        this.loading = false;
        this.issuesSize = data.size;

        if (emptyIssues) {
          this.issues = [];
        }

        this.createIssues(data.issues);

        return data;
      });
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
      this.addIssue(new ListIssue(issueObj, this.defaultAvatar));
    });
  }

  addMultipleIssues(issues, listFrom, newIndex) {
    let moveBeforeId = null;
    let moveAfterId = null;

    const listHasIssues = issues.every(issue => this.findIssue(issue.id));

    if (!listHasIssues) {
      if (newIndex !== undefined) {
        if (this.issues[newIndex - 1]) {
          moveBeforeId = this.issues[newIndex - 1].id;
        }

        if (this.issues[newIndex]) {
          moveAfterId = this.issues[newIndex].id;
        }

        this.issues.splice(newIndex, 0, ...issues);
      } else {
        this.issues.push(...issues);
      }

      if (this.label) {
        issues.forEach(issue => issue.addLabel(this.label));
      }

      if (this.assignee) {
        if (listFrom && listFrom.type === 'assignee') {
          issues.forEach(issue => issue.removeAssignee(listFrom.assignee));
        }
        issues.forEach(issue => issue.addAssignee(this.assignee));
      }

      if (IS_EE && this.milestone) {
        if (listFrom && listFrom.type === 'milestone') {
          issues.forEach(issue => issue.removeMilestone(listFrom.milestone));
        }
        issues.forEach(issue => issue.addMilestone(this.milestone));
      }

      if (listFrom) {
        this.issuesSize += issues.length;

        this.updateMultipleIssues(issues, listFrom, moveBeforeId, moveAfterId);
      }
    }
  }

  addIssue(issue, listFrom, newIndex) {
    let moveBeforeId = null;
    let moveAfterId = null;

    if (!this.findIssue(issue.id)) {
      if (newIndex !== undefined) {
        this.issues.splice(newIndex, 0, issue);

        if (this.issues[newIndex - 1]) {
          moveBeforeId = this.issues[newIndex - 1].id;
        }

        if (this.issues[newIndex + 1]) {
          moveAfterId = this.issues[newIndex + 1].id;
        }
      } else {
        this.issues.push(issue);
      }

      if (this.label) {
        issue.addLabel(this.label);
      }

      if (this.assignee) {
        if (listFrom && listFrom.type === 'assignee') {
          issue.removeAssignee(listFrom.assignee);
        }
        issue.addAssignee(this.assignee);
      }

      if (IS_EE && this.milestone) {
        if (listFrom && listFrom.type === 'milestone') {
          issue.removeMilestone(listFrom.milestone);
        }
        issue.addMilestone(this.milestone);
      }

      if (listFrom) {
        this.issuesSize += 1;

        this.updateIssueLabel(issue, listFrom, moveBeforeId, moveAfterId);
      }
    }
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
