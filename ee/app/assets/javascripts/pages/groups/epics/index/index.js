import FilteredSearchManager from '~/filtered_search/filtered_search_manager';
import FilteredSearchTokenKeysEpics from 'ee/filtered_search/filtered_search_token_keys_epics';

document.addEventListener('DOMContentLoaded', () => {
  const filteredSearchEnabled = FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new FilteredSearchManager({
      page: 'epics',
      filteredSearchTokenKeys: FilteredSearchTokenKeysEpics,
      stateFiltersSelector: '.epics-state-filters',
    });
    filteredSearchManager.setup();
  }
});
