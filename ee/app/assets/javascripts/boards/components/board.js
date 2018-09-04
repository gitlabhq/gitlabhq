import '~/boards/components/board';
import { __, n__, sprintf } from '~/locale';
import boardPromotionState from 'ee/boards/components/board_promotion_state';

const Store = gl.issueBoards.BoardsStore;
const base = gl.issueBoards.Board;

gl.issueBoards.Board = base.extend({
  data() {
    return {
      weightFeatureAvailable: Store.weightFeatureAvailable,
    };
  },
  components: {
    boardPromotionState,
  },
  computed: {
    counterTooltip() {
      if (!this.weightFeatureAvailable) {
        // call computed property from base component (CE board.js)
        return base.options.computed.counterTooltip.call(this);
      }

      const { issuesSize, totalWeight } = this.list;
      return sprintf(__(
        `${n__('%d issue', '%d issues', issuesSize)} with %{totalWeight} total weight`),
        {
          totalWeight,
        },
      );
    },
  },
});
