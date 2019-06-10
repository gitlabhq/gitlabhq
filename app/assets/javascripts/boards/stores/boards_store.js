/* eslint-disable no-shadow */
/* global List */

import $ from 'jquery';
import _ from 'underscore';
import Vue from 'vue';
import Cookies from 'js-cookie';
import BoardsStoreEE from 'ee_else_ce/boards/stores/boards_store_ee';
import { getUrlParamsArray, parseBoolean } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import eventHub from '../eventhub';

const boardsStore = {
  disabled: false,
  scopedLabels: {
    helpLink: '',
    enabled: false,
  },
  filter: {
    path: '',
  },
  state: {
    currentBoard: {
      labels: [],
    },
    currentPage: '',
    reload: false,
  },
  detail: {
    issue: {},
  },
  moving: {
    issue: {},
    list: {},
  },
  create() {
    this.state.lists = [];
    this.filter.path = getUrlParamsArray().join('&');
    this.detail = {
      issue: {},
    };
  },
  showPage(page) {
    this.state.reload = false;
    this.state.currentPage = page;
  },
  addList(listObj, defaultAvatar) {
    const list = new List(listObj, defaultAvatar);
    this.state.lists = _.sortBy([...this.state.lists, list], 'position');

    return list;
  },
  new(listObj) {
    const list = this.addList(listObj);
    const backlogList = this.findList('type', 'backlog', 'backlog');

    list
      .save()
      .then(() => {
        // Remove any new issues from the backlog
        // as they will be visible in the new list
        list.issues.forEach(backlogList.removeIssue.bind(backlogList));
        this.state.lists = _.sortBy(this.state.lists, 'position');
      })
      .catch(() => {
        // https://gitlab.com/gitlab-org/gitlab-ce/issues/30821
      });
    this.removeBlankState();
  },
  updateNewListDropdown(listId) {
    $(`.js-board-list-${listId}`).removeClass('is-active');
  },
  shouldAddBlankState() {
    // Decide whether to add the blank state
    return !this.state.lists.filter(list => list.type !== 'backlog' && list.type !== 'closed')[0];
  },
  addBlankState() {
    if (!this.shouldAddBlankState() || this.welcomeIsHidden() || this.disabled) return;

    this.addList({
      id: 'blank',
      list_type: 'blank',
      title: __('Welcome to your Issue Board!'),
      position: 0,
    });
  },
  removeBlankState() {
    this.removeList('blank');

    Cookies.set('issue_board_welcome_hidden', 'true', {
      expires: 365 * 10,
      path: '',
    });
  },
  welcomeIsHidden() {
    return parseBoolean(Cookies.get('issue_board_welcome_hidden'));
  },
  removeList(id, type = 'blank') {
    const list = this.findList('id', id, type);

    if (!list) return;

    this.state.lists = this.state.lists.filter(list => list.id !== id);
  },
  moveList(listFrom, orderLists) {
    orderLists.forEach((id, i) => {
      const list = this.findList('id', parseInt(id, 10));

      list.position = i;
    });
    listFrom.update();
  },

  startMoving(list, issue) {
    Object.assign(this.moving, { list, issue });
  },

  moveIssueToList(listFrom, listTo, issue, newIndex) {
    const issueTo = listTo.findIssue(issue.id);
    const issueLists = issue.getLists();
    const listLabels = issueLists.map(listIssue => listIssue.label);

    if (!issueTo) {
      // Check if target list assignee is already present in this issue
      if (
        listTo.type === 'assignee' &&
        listFrom.type === 'assignee' &&
        issue.findAssignee(listTo.assignee)
      ) {
        const targetIssue = listTo.findIssue(issue.id);
        targetIssue.removeAssignee(listFrom.assignee);
      } else if (listTo.type === 'milestone') {
        const currentMilestone = issue.milestone;
        const currentLists = this.state.lists
          .filter(list => list.type === 'milestone' && list.id !== listTo.id)
          .filter(list => list.issues.some(listIssue => issue.id === listIssue.id));

        issue.removeMilestone(currentMilestone);
        issue.addMilestone(listTo.milestone);
        currentLists.forEach(currentList => currentList.removeIssue(issue));
        listTo.addIssue(issue, listFrom, newIndex);
      } else {
        // Add to new lists issues if it doesn't already exist
        listTo.addIssue(issue, listFrom, newIndex);
      }
    } else {
      listTo.updateIssueLabel(issue, listFrom);
      issueTo.removeLabel(listFrom.label);
    }

    if (listTo.type === 'closed' && listFrom.type !== 'backlog') {
      issueLists.forEach(list => {
        list.removeIssue(issue);
      });
      issue.removeLabels(listLabels);
    } else if (listTo.type === 'backlog' && listFrom.type === 'assignee') {
      issue.removeAssignee(listFrom.assignee);
      listFrom.removeIssue(issue);
    } else if (listTo.type === 'backlog' && listFrom.type === 'milestone') {
      issue.removeMilestone(listFrom.milestone);
      listFrom.removeIssue(issue);
    } else if (this.shouldRemoveIssue(listFrom, listTo)) {
      listFrom.removeIssue(issue);
    }
  },
  shouldRemoveIssue(listFrom, listTo) {
    return (
      (listTo.type !== 'label' && listFrom.type === 'assignee') ||
      (listTo.type !== 'assignee' && listFrom.type === 'label') ||
      listFrom.type === 'backlog'
    );
  },
  moveIssueInList(list, issue, oldIndex, newIndex, idArray) {
    const beforeId = parseInt(idArray[newIndex - 1], 10) || null;
    const afterId = parseInt(idArray[newIndex + 1], 10) || null;

    list.moveIssue(issue, oldIndex, newIndex, beforeId, afterId);
  },
  findList(key, val, type = 'label') {
    const filteredList = this.state.lists.filter(list => {
      const byType = type
        ? list.type === type || list.type === 'assignee' || list.type === 'milestone'
        : true;

      return list[key] === val && byType;
    });
    return filteredList[0];
  },
  findListByLabelId(id) {
    return this.state.lists.find(list => list.type === 'label' && list.label.id === id);
  },

  toggleFilter(filter) {
    const filterPath = this.filter.path.split('&');
    const filterIndex = filterPath.indexOf(filter);

    if (filterIndex === -1) {
      filterPath.push(filter);
    } else {
      filterPath.splice(filterIndex, 1);
    }

    this.filter.path = filterPath.join('&');

    this.updateFiltersUrl();

    eventHub.$emit('updateTokens');
  },

  setListDetail(newList) {
    this.detail.list = newList;
  },

  updateFiltersUrl() {
    window.history.pushState(null, null, `?${this.filter.path}`);
  },

  clearDetailIssue() {
    this.setIssueDetail({});
  },

  setIssueDetail(issueDetail) {
    this.detail.issue = issueDetail;
  },
};

BoardsStoreEE.initEESpecific(boardsStore);

// hacks added in order to allow milestone_select to function properly
// TODO: remove these

export function boardStoreIssueSet(...args) {
  Vue.set(boardsStore.detail.issue, ...args);
}

export function boardStoreIssueDelete(...args) {
  Vue.delete(boardsStore.detail.issue, ...args);
}

export default boardsStore;
