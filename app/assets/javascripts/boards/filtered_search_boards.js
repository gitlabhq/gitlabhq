export default class FilteredSearchBoards extends gl.FilteredSearchManager {
  constructor(store, updateUrl = false) {
    super('boards');

    this.store = store;
    this.updateUrl = updateUrl;
    this.isHandledAsync = true;
  }

  updateObject(path) {
    this.store.path = path.substr(1);

    if (this.updateUrl) {
      gl.issueBoards.BoardsStore.updateFiltersUrl();
    }
  }
}
