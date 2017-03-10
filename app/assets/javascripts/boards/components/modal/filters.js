/* global Vue */
import FilteredSearchBoards from '../../filtered_search_boards';
import { FilteredSearchContainer } from '../../../filtered_search/container';

export default {
  name: 'modal-filters',
  mounted() {
    FilteredSearchContainer.container = this.$el;

    this.filteredSearch = new FilteredSearchBoards({path: ''}, false);
  },
  destroyed() {
    FilteredSearchContainer.container = document;
    gl.issueBoards.ModalStore.setDefaultFilter();
  },
  template: '#js-board-modal-filter',
};
