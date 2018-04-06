import { EPIC_DETAILS_CELL_WIDTH, TIMELINE_CELL_MIN_WIDTH, SCROLL_BAR_SIZE } from '../constants';

export default {
  computed: {
    /**
     * Return section width after reducing scrollbar size
     * based on listScrollable such that Epic item cells
     * do not consider scrollbar presence in shellWidth
     */
    sectionShellWidth() {
      return this.shellWidth - (this.listScrollable ? SCROLL_BAR_SIZE : 0);
    },
    sectionItemWidth() {
      const timeframeLength = this.timeframe.length;

      // Calculate minimum width for single cell
      // based on total number of months in current timeframe
      // and available shellWidth
      const width = (this.sectionShellWidth - EPIC_DETAILS_CELL_WIDTH) / timeframeLength;

      // When shellWidth is too low, we need to obey global
      // minimum cell width.
      return Math.max(width, TIMELINE_CELL_MIN_WIDTH);
    },
    sectionContainerStyles() {
      const width = EPIC_DETAILS_CELL_WIDTH + (this.sectionItemWidth * this.timeframe.length);
      return {
        width: `${width}px`,
      };
    },
  },
};
