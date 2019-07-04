/* eslint-disable class-methods-use-this */

import boardsStore from '~/boards/stores/boards_store';

export default class BoardService {
  generateBoardsPath(id) {
    return boardsStore.generateBoardsPath(id);
  }

  generateIssuesPath(id) {
    return boardsStore.generateIssuesPath(id);
  }

  static generateIssuePath(boardId, id) {
    return boardsStore.generateIssuePath(boardId, id);
  }

  all() {
    return boardsStore.all();
  }

  generateDefaultLists() {
    return boardsStore.generateDefaultLists();
  }

  createList(entityId, entityType) {
    return boardsStore.createList(entityId, entityType);
  }

  updateList(id, position) {
    return boardsStore.updateList(id, position);
  }

  destroyList(id) {
    return boardsStore.destroyList(id);
  }

  getIssuesForList(id, filter = {}) {
    return boardsStore.getIssuesForList(id, filter);
  }

  moveIssue(id, fromListId = null, toListId = null, moveBeforeId = null, moveAfterId = null) {
    return boardsStore.moveIssue(id, fromListId, toListId, moveBeforeId, moveAfterId);
  }

  newIssue(id, issue) {
    return boardsStore.newIssue(id, issue);
  }

  getBacklog(data) {
    return boardsStore.getBacklog(data);
  }

  bulkUpdate(issueIds, extraData = {}) {
    return boardsStore.bulkUpdate(issueIds, extraData);
  }

  static getIssueInfo(endpoint) {
    return boardsStore.getIssueInfo(endpoint);
  }

  static toggleIssueSubscription(endpoint) {
    return boardsStore.toggleIssueSubscription(endpoint);
  }
}

window.BoardService = BoardService;
