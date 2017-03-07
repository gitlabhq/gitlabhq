export default class FilteredSearchBoards extends gl.FilteredSearchManager {
  constructor(store) {
    super('boards');

    this.store = store;
    this.isHandledAsync = true;
  }

  updateObject(path) {
    this.store.path = path.substr(1);

    gl.issueBoards.BoardsStore.updateFiltersUrl();
  }
}
