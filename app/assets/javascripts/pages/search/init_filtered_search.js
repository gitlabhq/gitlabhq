import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';

export default ({
  page,
  filteredSearchTokenKeys,
  isGroup,
  isGroupAncestor,
  isGroupDecendent,
  useDefaultState,
  stateFiltersSelector,
  anchor,
}) => {
  const filteredSearchEnabled = FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new FilteredSearchManager({
      page,
      isGroup,
      isGroupAncestor,
      isGroupDecendent,
      useDefaultState,
      filteredSearchTokenKeys,
      stateFiltersSelector,
      anchor,
    });
    filteredSearchManager.setup();
  }
};
