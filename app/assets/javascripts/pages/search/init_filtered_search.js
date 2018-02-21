import FilteredSearchManager from '~/filtered_search/filtered_search_manager';

<<<<<<< HEAD
export default ({ page, filteredSearchTokenKeys, stateFiltersSelector }) => {
  const filteredSearchEnabled = FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new FilteredSearchManager({
      page,
      filteredSearchTokenKeys,
      stateFiltersSelector,
    });
=======
export default ({ page }) => {
  const filteredSearchEnabled = FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new FilteredSearchManager({ page });
>>>>>>> upstream/master
    filteredSearchManager.setup();
  }
};
