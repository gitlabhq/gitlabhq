import '~/boards/components/board';
import { __, n__, sprintf } from '~/locale';
import boardPromotionState from 'ee/boards/components/board_promotion_state';

const base = gl.issueBoards.Board;

gl.issueBoards.Board = base.extend({
  components: {
    boardPromotionState,
  },
  computed: {
    counterTooltip() {
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
