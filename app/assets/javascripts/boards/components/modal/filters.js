import FilteredSearchBoards from '../../filtered_search_boards';
import FilteredSearchContainer from '../../../filtered_search/container';
import vuexstore from '~/boards/stores';

export default {
  name: 'modal-filters',
  props: {
    store: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    FilteredSearchContainer.container = this.$el;

    this.filteredSearch = new FilteredSearchBoards(this.store, vuexstore);
    this.filteredSearch.setup();
    this.filteredSearch.removeTokens();
    this.filteredSearch.handleInputPlaceholder();
    this.filteredSearch.toggleClearSearchButton();
  },
  destroyed() {
    this.filteredSearch.cleanup();
    FilteredSearchContainer.container = document;
    this.store.path = '';
  },
  template: '#js-board-modal-filter',
};
