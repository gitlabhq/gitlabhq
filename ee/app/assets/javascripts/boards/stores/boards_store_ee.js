/* eslint-disable class-methods-use-this */
import Cookies from 'js-cookie';

class BoardsStoreEE {
  initEESpecific(boardsStore) {
    this.$boardApp = document.getElementById('board-app');
    this.store = boardsStore;
    this.store.addPromotionState = () => {
      this.addPromotion();
    };
    this.store.removePromotionState = () => {
      this.removePromotion();
    };
    this.store.boardConfig = {
      id: false,
      name: '',
      labels: [],
      milestone: {},
      assignee: {},
      weight: null,
    };
    this.store.updateBoardConfig = this.updateBoardConfig;
  }

  updateBoardConfig(board = {}) {
    this.boardConfig.id = board.id;
    this.boardConfig.name = board.name;
    this.boardConfig.milestone = board.milestone;
    this.boardConfig.labels = board.labels || [];
    this.boardConfig.assignee = board.assignee || {};
    this.boardConfig.weight = board.weight;
  }

  shouldAddPromotionState() {
    // Decide whether to add the promotion state
    return this.$boardApp.dataset.showPromotion === 'true';
  }

  addPromotion() {
    if (!this.shouldAddPromotionState() || this.promotionIsHidden() || this.store.disabled) return;

    this.store.addList({
      id: 'promotion',
      list_type: 'promotion',
      title: 'Improve Issue boards',
      position: 0,
    });

    this.store.state.lists = _.sortBy(this.store.state.lists, 'position');
  }

  removePromotion() {
    this.store.removeList('promotion', 'promotion');

    Cookies.set('promotion_issue_board_hidden', 'true', {
      expires: 365 * 10,
      path: '',
    });
  }

  promotionIsHidden() {
    return Cookies.get('promotion_issue_board_hidden') === 'true';
  }
}

export default new BoardsStoreEE();
