export default ({ page, filteredSearchTokenKeys, stateFiltersSelector }) => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager({
      page,
      filteredSearchTokenKeys,
      stateFiltersSelector,
    });
    filteredSearchManager.setup();
  }
};
