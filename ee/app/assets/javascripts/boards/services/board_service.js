import axios from '~/lib/utils/axios_utils';
import BoardService from '~/boards/services/board_service';

export default class BoardServiceEE extends BoardService {
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
  }

  static updateWeight(endpoint, weight = null) {
    return axios.put(endpoint, {
      weight,
    });
  }
}
