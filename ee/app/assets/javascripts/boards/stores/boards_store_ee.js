/* eslint-disable class-methods-use-this */
import _ from 'underscore';
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

    const baseCreate = this.store.create.bind(this.store);
    this.store.create = () => {
      baseCreate();
      if (this.$boardApp) {
        this.store.boardConfig = {
          milestoneId: parseInt(this.$boardApp.dataset.boardMilestoneId, 10),
          milestoneTitle: this.$boardApp.dataset.boardMilestoneTitle || '',
          assigneeUsername: this.$boardApp.dataset.boardAssigneeUsername,
          labels: JSON.parse(this.$boardApp.dataset.labels || []),
          weight: parseInt(this.$boardApp.dataset.boardWeight, 10),
        };
        this.store.cantEdit = [];
        this.initBoardFilters();
      }
    };
  }

  initBoardFilters() {
    const updateFilterPath = (key, value) => {
      if (!value) return;
      const querystring = `${key}=${value}`;
      this.store.filter.path = [querystring].concat(
        this.store.filter.path.split('&').filter(param => param.match(new RegExp(`^${key}=(.*)$`, 'g')) === null),
      ).join('&');
    };

    let milestoneTitle = this.store.boardConfig.milestoneTitle;
    if (this.store.boardConfig.milestoneId === 0) {
      milestoneTitle = 'No+Milestone';
    } else {
      milestoneTitle = encodeURIComponent(milestoneTitle);
    }
    if (milestoneTitle) {
      updateFilterPath('milestone_title', milestoneTitle);
      this.store.cantEdit.push('milestone');
    }

    let weight = this.store.boardConfig.weight;
    if (weight !== -1) {
      if (weight === 0) {
        weight = 'No+Weight';
      }
      updateFilterPath('weight', weight);
      this.store.cantEdit.push('weight');
    }
    updateFilterPath('assignee_username', this.store.boardConfig.assigneeUsername);
    if (this.store.boardConfig.assigneeUsername) {
      this.store.cantEdit.push('assignee');
    }

    const filterPath = this.store.filter.path.split('&');
    this.store.boardConfig.labels.forEach((label) => {
      const labelTitle = encodeURIComponent(label.title);
      const param = `label_name[]=${labelTitle}`;
      const labelIndex = filterPath.indexOf(param);

      if (labelIndex === -1) {
        filterPath.push(param);
      }

      this.store.cantEdit.push({
        name: 'label',
        value: label.title,
      });
    });

    this.store.filter.path = filterPath.join('&');

    this.store.updateFiltersUrl(true);
  }

  addPromotion() {
    if (!this.$boardApp.hasAttribute('data-show-promotion') || this.promotionIsHidden() || this.store.disabled) return;

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
