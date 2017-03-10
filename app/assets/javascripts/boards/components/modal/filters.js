/* global Vue */
import FilteredSearchBoards from '../../filtered_search_boards';

export default {
  name: 'modal-filters',
  mounted() {
    this.filteredSearch = new FilteredSearchBoards({path: ''}, false, this.$el);
  },
  destroyed() {
    gl.issueBoards.ModalStore.setDefaultFilter();
  },
  template: '#js-board-modal-filter',
};
