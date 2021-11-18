import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { getExperimentVariant } from '~/experimentation/utils';
import { CANDIDATE_VARIANT } from '~/experimentation/constants';
import NewBoardButton from './components/new_board_button.vue';

export default () => {
  if (getExperimentVariant('prominent_create_board_btn') !== CANDIDATE_VARIANT) {
    return;
  }

  const el = document.querySelector('.js-new-board');

  if (!el) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    provide: {
      multipleIssueBoardsAvailable: parseBoolean(el.dataset.multipleIssueBoardsAvailable),
      canAdminBoard: parseBoolean(el.dataset.canAdminBoard),
    },
    render(h) {
      return h(NewBoardButton);
    },
  });
};
