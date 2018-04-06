/* eslint-disable comma-dangle, space-before-function-paren, one-var, no-shadow, dot-notation, max-len */
/* global List */

import $ from 'jquery';
import _ from 'underscore';
import Cookies from 'js-cookie';
import boardsStoreEE from 'ee/boards/stores/boards_store_ee';
import { getUrlParamsArray } from '~/lib/utils/common_utils';

window.gl = window.gl || {};
window.gl.issueBoards = window.gl.issueBoards || {};

gl.issueBoards.BoardsStore = {
  disabled: false,
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
  create () {
    this.state.lists = [];
    this.filter.path = getUrlParamsArray().join('&');
    this.detail = {
      issue: {},
    };
  },
  createNewListDropdownData() {
    this.state.currentBoard = {
      labels: [],
    };
    this.state.currentPage = '';
    this.state.reload = false;
  },
  showPage(page) {
    this.state.reload = false;
    this.state.currentPage = page;
  },
  addList (listObj, defaultAvatar) {
    const list = new List(listObj, defaultAvatar);
    this.state.lists.push(list);

    return list;
  },
  new (listObj) {
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
  updateNewListDropdown (listId) {
    $(`.js-board-list-${listId}`).removeClass('is-active');
  },
  shouldAddBlankState () {
    // Decide whether to add the blank state
    return !(this.state.lists.filter(list => list.type !== 'backlog' && list.type !== 'closed')[0]);
  },
  addBlankState () {
    if (!this.shouldAddBlankState() || this.welcomeIsHidden() || this.disabled) return;

    this.addList({
      id: 'blank',
      list_type: 'blank',
      title: 'Welcome to your Issue Board!',
      position: 0
    });

    this.state.lists = _.sortBy(this.state.lists, 'position');
  },
  removeBlankState () {
    this.removeList('blank');

    Cookies.set('issue_board_welcome_hidden', 'true', {
      expires: 365 * 10,
      path: ''
    });
  },
  welcomeIsHidden () {
    return Cookies.get('issue_board_welcome_hidden') === 'true';
  },
  removeList (id, type = 'blank') {
    const list = this.findList('id', id, type);

    if (!list) return;

    this.state.lists = this.state.lists.filter(list => list.id !== id);
  },
  moveList (listFrom, orderLists) {
    orderLists.forEach((id, i) => {
      const list = this.findList('id', parseInt(id, 10));

      list.position = i;
    });
    listFrom.update();
  },
  moveIssueToList (listFrom, listTo, issue, newIndex) {
    const issueTo = listTo.findIssue(issue.id);
    const issueLists = issue.getLists();
    const listLabels = issueLists.map(listIssue => listIssue.label);

    if (!issueTo) {
      // Add to new lists issues if it doesn't already exist
      listTo.addIssue(issue, listFrom, newIndex);
    } else {
      listTo.updateIssueLabel(issue, listFrom);
      issueTo.removeLabel(listFrom.label);
    }

    if (listTo.type === 'closed' && listFrom.type !== 'backlog') {
      issueLists.forEach((list) => {
        list.removeIssue(issue);
      });
      issue.removeLabels(listLabels);
    } else {
      listFrom.removeIssue(issue);
    }
  },
  moveIssueInList (list, issue, oldIndex, newIndex, idArray) {
    const beforeId = parseInt(idArray[newIndex - 1], 10) || null;
    const afterId = parseInt(idArray[newIndex + 1], 10) || null;

    list.moveIssue(issue, oldIndex, newIndex, beforeId, afterId);
  },
  findList (key, val, type = 'label') {
    return this.state.lists.filter((list) => {
      const byType = type ? list['type'] === type : true;

      return list[key] === val && byType;
    })[0];
  },
  updateFiltersUrl (replaceState = false) {
    if (replaceState) {
      history.replaceState(null, null, `?${this.filter.path}`);
    } else {
      history.pushState(null, null, `?${this.filter.path}`);
    }
  },
};

boardsStoreEE.initEESpecific(gl.issueBoards.BoardsStore);
