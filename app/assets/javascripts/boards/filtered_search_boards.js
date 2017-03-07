export default class FilteredSearchBoards extends gl.FilteredSearchManager {
  constructor(store) {
    super('boards');

    this.store = store;
    this.destroyOnSubmit = false
  }

  updateObject(path) {
    this.store.path = path.substr(1);
  }
}
