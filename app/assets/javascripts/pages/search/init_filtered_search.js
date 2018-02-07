<<<<<<< HEAD
export default ({ page, filteredSearchTokenKeys, stateFiltersSelector }) => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager({
      page,
      filteredSearchTokenKeys,
      stateFiltersSelector,
    });
=======
export default ({ page }) => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager({ page });
>>>>>>> upstream/master
    filteredSearchManager.setup();
  }
};
