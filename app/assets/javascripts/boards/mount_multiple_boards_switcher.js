import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import BoardsSelector from '~/boards/components/boards_selector.vue';

export default () => {
  const boardsSwitcherElement = document.getElementById('js-multiple-boards-switcher');
  return new Vue({
    el: boardsSwitcherElement,
    components: {
      BoardsSelector,
    },
    data() {
      const { dataset } = boardsSwitcherElement;

      const boardsSelectorProps = {
        ...dataset,
        currentBoard: JSON.parse(dataset.currentBoard),
        hasMissingBoards: parseBoolean(dataset.hasMissingBoards),
        canAdminBoard: parseBoolean(dataset.canAdminBoard),
        multipleIssueBoardsAvailable: parseBoolean(dataset.multipleIssueBoardsAvailable),
        projectId: Number(dataset.projectId),
        groupId: Number(dataset.groupId),
        scopedIssueBoardFeatureEnabled: parseBoolean(dataset.scopedIssueBoardFeatureEnabled),
        weights: JSON.parse(dataset.weights),
      };

      return { boardsSelectorProps };
    },
    render(createElement) {
      return createElement(BoardsSelector, {
        props: this.boardsSelectorProps,
      });
    },
  });
};
