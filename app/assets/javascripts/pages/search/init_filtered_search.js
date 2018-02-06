export default (page) => {
  const filteredSearchEnabled = gl.FilteredSearchManager && document.querySelector('.filtered-search');
  if (filteredSearchEnabled) {
    const filteredSearchManager = new gl.FilteredSearchManager(page);
    filteredSearchManager.setup();
  }
};
