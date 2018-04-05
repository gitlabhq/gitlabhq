import axios from '../../lib/utils/axios_utils';
import { mergeUrlParams } from '../../lib/utils/url_utility';

export default class BoardService {
  constructor({ boardsEndpoint, listsEndpoint, bulkUpdatePath, boardId }) {
    this.boardsEndpoint = boardsEndpoint;
    this.boardId = boardId;
    this.listsEndpoint = listsEndpoint;
    this.listsEndpointGenerate = `${listsEndpoint}/generate.json`;
    this.bulkUpdatePath = bulkUpdatePath;
  }

  generateBoardsPath(id) {
    return `${this.boardsEndpoint}${id ? `/${id}` : ''}.json`;
  }

  generateIssuesPath(id) {
    return `${this.listsEndpoint}${id ? `/${id}` : ''}/issues`;
  }

  static generateIssuePath(boardId, id) {
    return `${gon.relative_url_root}/-/boards/${boardId ? `${boardId}` : ''}/issues${id ? `/${id}` : ''}`;
<<<<<<< HEAD
  }

  allBoards() {
    return axios.get(this.generateBoardsPath());
  }

  createBoard(board) {
    const boardPayload = { ...board };
    boardPayload.label_ids = (board.labels || []).map(b => b.id);

    if (boardPayload.label_ids.length === 0) {
      boardPayload.label_ids = [''];
    }

    if (boardPayload.assignee) {
      boardPayload.assignee_id = boardPayload.assignee.id;
    }

    if (boardPayload.milestone) {
      boardPayload.milestone_id = boardPayload.milestone.id;
    }

    if (boardPayload.id) {
      return axios.put(this.generateBoardsPath(boardPayload.id), { board: boardPayload });
    }
    return axios.post(this.generateBoardsPath(), { board: boardPayload });
  }

  deleteBoard({ id }) {
    return axios.delete(this.generateBoardsPath(id));
=======
>>>>>>> upstream/master
  }

  all() {
    return axios.get(this.listsEndpoint);
  }

  generateDefaultLists() {
    return axios.post(this.listsEndpointGenerate, {});
  }

  createList(labelId) {
    return axios.post(this.listsEndpoint, {
      list: {
        label_id: labelId,
      },
    });
  }

  updateList(id, position) {
    return axios.put(`${this.listsEndpoint}/${id}`, {
      list: {
        position,
      },
    });
  }

  destroyList(id) {
    return axios.delete(`${this.listsEndpoint}/${id}`);
  }

  getIssuesForList(id, filter = {}) {
    const data = { id };
    Object.keys(filter).forEach((key) => { data[key] = filter[key]; });

    return axios.get(mergeUrlParams(data, this.generateIssuesPath(id)));
  }

  moveIssue(id, fromListId = null, toListId = null, moveBeforeId = null, moveAfterId = null) {
    return axios.put(BoardService.generateIssuePath(this.boardId, id), {
      from_list_id: fromListId,
      to_list_id: toListId,
      move_before_id: moveBeforeId,
      move_after_id: moveAfterId,
    });
  }

  newIssue(id, issue) {
    return axios.post(this.generateIssuesPath(id), {
      issue,
    });
  }

  getBacklog(data) {
    return axios.get(mergeUrlParams(data, `${gon.relative_url_root}/-/boards/${this.boardId}/issues.json`));
  }

  bulkUpdate(issueIds, extraData = {}) {
    const data = {
      update: Object.assign(extraData, {
        issuable_ids: issueIds.join(','),
      }),
    };

    return axios.post(this.bulkUpdatePath, data);
  }

  static getIssueInfo(endpoint) {
    return axios.get(endpoint);
  }

  static updateWeight(endpoint, weight = null) {
    return axios.put(endpoint, {
      weight,
    });
  }

  static toggleIssueSubscription(endpoint) {
    return axios.post(endpoint);
  }
}

window.BoardService = BoardService;
