import Vue from 'vue';
import VueApollo from 'vue-apollo';
import BoardsSelector from 'ee_else_ce/boards/components/boards_selector.vue';
import store from '~/boards/stores';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (params = {}) => {
  const boardsSwitcherElement = document.getElementById('js-multiple-boards-switcher');
  const { dataset } = boardsSwitcherElement;
  return new Vue({
    el: boardsSwitcherElement,
    components: {
      BoardsSelector,
    },
    apolloProvider,
    store,
    provide: {
      fullPath: params.fullPath,
      rootPath: params.rootPath,
      recentBoardsEndpoint: params.recentBoardsEndpoint,
      allowScopedLabels: params.allowScopedLabels,
      labelsManagePath: params.labelsManagePath,
      allowLabelCreate: parseBoolean(dataset.canAdminBoard),
    },
    data() {
      const boardsSelectorProps = {
        ...dataset,
        hasMissingBoards: parseBoolean(dataset.hasMissingBoards),
        canAdminBoard: parseBoolean(dataset.canAdminBoard),
        multipleIssueBoardsAvailable: parseBoolean(dataset.multipleIssueBoardsAvailable),
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
