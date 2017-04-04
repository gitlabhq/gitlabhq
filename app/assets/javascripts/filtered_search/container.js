/* eslint-disable class-methods-use-this */
let container = document;

class FilteredSearchContainerClass {
  set container(containerParam) {
    container = containerParam;
  }

  get container() {
    return container;
  }
}

export default new FilteredSearchContainerClass();
