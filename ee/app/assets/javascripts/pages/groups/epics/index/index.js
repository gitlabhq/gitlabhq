import FilteredSearchTokenKeysEpics from 'ee/filtered_search/filtered_search_token_keys_epics';

export default () => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager({
      page: 'epics',
      filteredSearchTokenKeys: FilteredSearchTokenKeysEpics,
      stateFiltersSelector: '.epics-state-filters',
    });
    filteredSearchManager.setup();
  }
};
