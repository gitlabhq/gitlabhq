import FilteredSearchManager from '~/filtered_search/filtered_search_manager';

<<<<<<< HEAD
export default ({ page, filteredSearchTokenKeys, stateFiltersSelector }) => {
=======
export default ({
  page,
  filteredSearchTokenKeys,
  isGroup,
  isGroupAncestor,
  stateFiltersSelector,
}) => {
>>>>>>> upstream/master
  const filteredSearchEnabled = FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new FilteredSearchManager({
      page,
<<<<<<< HEAD
=======
      isGroup,
      isGroupAncestor,
>>>>>>> upstream/master
      filteredSearchTokenKeys,
      stateFiltersSelector,
    });
    filteredSearchManager.setup();
  }
};
